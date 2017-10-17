[![Build Status](https://travis-ci.org/zoffixznet/perl6-Reminders.svg)](https://travis-ci.org/zoffixznet/perl6-Reminders)

# NAME

`Reminders` - Class for managing reminders about task and events

# SYNOPSIS

```perl6
    use Reminders;

    my Reminders $rem .= new;
    say "Setting up some reminders up to 20 seconds in the future";
    $rem.add: '5 seconds passed',  :5in;
    $rem.add: '15 seconds passed', :when(now+15), :who<Zoffix>, :where<#perl6>;

    react whenever $rem {
        say "Reminder: $^reminder";
        once $rem.add('One more thing, bruh', :15in).done;
    }

    # OUTPUT (exits after printing last line):
    # Reminder: 5 seconds passed
    # Reminder: Zoffix@#perl6 15 seconds passed
    # Reminder: One more thing, bruh
```

# DESCRIPTION

You ask the class to remind you with stuff, tagged with an optional name and
location. When the time comes, the class will emit the reminder to a `Supply`.
The reminders are stored in an SQLite database, so even if you close the
program, you will still get your reminders the next time you fire it up.

# METHODS

## class `Reminders`

### `new`

```perl6
    submethod TWEAK(IO() :$db-file = 'reminders.sqlite.db')
```

Creates a new `Reminders` object. Takes an optional `:$db-file` named arg
specifying the SQLite database file location. The file will be automatically
created and SQL schema deployed if the file does not exist.

If the database has any unseen reminders with their due times reached, they
will be emited.

```perl6
    my Reminders $rem .= new;
    my Reminders $rem-custom .= new: :db-file<my-special-reminders.db>;
```

### `add`

```perl6
    multi method add (UInt:D :$in!, |c --> Reminders:D)
    multi method add (
                Str:D  \what,
                Str:D  :$who   = '',
                Str:D  :$where = '',
        Instant(Any:D) :$when! where DateTime|Instant
        --> Reminders:D
    )
```

Returns the invocant. Adds a new reminder as string `what` to be emitted at the
`:$when` `Instant`. If `:$in` argument is used, the call is re-done with `:$when`
set to [`now`](https://docs.perl6.org/routine/now) plus `$in` seconds.
It's invalid to set both `:$in` and `:$when` at the same time.

Reminders with `:$when` set in the past are allowed and will be emitted immediately. If `:$when` is up to 10 seconds in the future from
[`now`](https://docs.perl6.org/routine/now), the reminder may be emitted
immediately.

Optional `:$who` and `:$where` arguments can be provided for arbitrary
classification of the reminder (these will be available via methods of the
emitted object).

```perl6
    $rem.add: 'one', :5in;       # may  be emitted immediately
    $rem.add: 'two', :in(-1000); # will be emitted immediately
    $rem.add: 'three', :when(DateTime.now.later: :year), # will be scheduled
              :who<Zoffix>, :where<#perl6>;
```

### `all`

```perl6
    method all (:$all --> List:D)
```

Returns a possibly-empty `List` of `Reminder::Rem` objects representing all
currently-unseen reminders, ordered by creation time, in descending order.
If `:$all` is set to a truthy value, returns all reminders in the database,
including those marked as seen.

```perl6
    .say for flat "You have these unseen reminders: ", $rem.all;
    # OUTPUT:
    # You have these unseen reminders:
    # get starship fuel

    .say for flat  "These are the reminders in the database: ", $rem.all: :all;
    # OUTPUT:
    # These are the reminders in the database:
    # pick up milk
    # get starship fuel
```

### `done`

```perl6
    method done (--> Nil)
```

Calls [`done`](https://docs.perl6.org/type/Supplier#method_done) on the
[`Supplier`](https://docs.perl6.org/type/Supplier) responsible for the
[`Supply`](https://docs.perl6.org/type/Supply) of reminder objects, one all
of them have been emitted.

Calling this method is optional and is just a convenience to break out of,
say, `react` loops. It's not permitted to `.add` more reminders once this
method have been called.

```perl6
    my Reminders $rem .= new;
    $rem.add: 'one', :3in;
    $rem.add: 'two', :5in;
    $rem.done;
    react whenever $rem { say "Reminder: $^reminder" }

    # OUTPUT (automatically exits after last line):
    # Reminder: one
    # Reminder: two
```

### `mark-seen`

```perl6
    multi method mark-seen (UInt:D \id --> Nil)
    multi method mark-seen (Reminders::Rem:D $rem --> Nil)
```

Takes a reminder object or just its `id` and marks it as "seen". Reminders
emitted into the `.Supply` are marked as "seen" automatically when emitted.

```perl6
    $rem.mark-seen: $_ for $rem.all.grep: *.what.contains: 'stuff I done already';
```

Marking an emitted reminder as "seen" will prevent it from being emitted, even
if it was already scheduled.

### `mark-unseen`

```perl6
    multi method mark-unseen (UInt:D \id, :$re-schedule --> Nil)
    multi method mark-unseen (Reminders::Rem:D $rem, :$re-schedule --> Nil)
```

Takes a reminder object or just its `id` and marks it as "unseen".
If `:$re-schedule` named argument is set to a truthy value, the reminder will
also be re-scheduled; note that if reminder's `.when` is in the past, that will
cause it to be immediately emitted and again marked as "seen".

```perl6
    $rem.mark-unseen: $_, :re-schedule
        for $rem.all.grep: *.what.contains: 'stuff I forgot to do';
```

### `rem`

```perl6
    method rem (UInt:D \id --> Reminders::Rem:D)
```

Takes an id of a reminder and returns the reminder object for it, or `Nil`
if a reminder with such an id was not found.

```perl6
    say "You're meant to do: " ~ $rem.rem(2).what;
```

### `remove`

```perl6
    multi method remove (UInt:D \id --> Nil)
    multi method remove (Reminders::Rem:D \rem --> Nil)
```

Takes a reminder object or its ID and deletes it from the database

```perl6
    $rem.remove: $_ for $rem.all.grep: *.what.contains: 'things I done';
```

### `remove`

```perl6
```


```perl6
```

### `remove`

```perl6
```


```perl6
```

# TESTING

To run the full test suite, set `EXTENDED_TESTING` environmental variable to `1`

# MULTI-THREADING

`Reminders` type is a [monitor](https://modules.perl6.org/dist/OO::Monitors),
so it's safe to multi-thread its methods.

However, currently, trying to use the **same database file** from multiple programs
or multiple `Reminders` instances might have issues due to race conditions or
crashes if SQLite or [`DBIish`](https://modules.perl6.org/dist/DBIish)
are not thread safe (no idea if they are).
---

#### REPOSITORY

Fork this module on GitHub:
https://github.com/zoffixznet/perl6-Reminders

#### BUGS

To report bugs or request features, please use
https://github.com/zoffixznet/perl6-Reminders/issues

#### AUTHOR

Zoffix Znet (http://perl6.party/)

#### LICENSE

You can use and distribute this module under the terms of the
The Artistic License 2.0. See the `LICENSE` file included in this
distribution for complete details.

The `META6.json` file of this distribution may be distributed and modified
without restrictions or attribution.
