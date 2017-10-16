[![Build Status](https://travis-ci.org/zoffixznet/perl6-Reminders.svg)](https://travis-ci.org/zoffixznet/perl6-Reminders)

# NAME

`Reminders` - Class for managing reminders about task and events

# SYNOPSIS

```perl6
    use lib <lib>;
    use Reminders;

    my $rem = Reminders.new;
    $rem.add: '12 seconds passed', :12in;
    $rem.add: '15 seconds passed', :when(now+15), :who<Zoffix>, :where<#perl6>;

    react whenever $rem {
        say "Reminder: $^reminder";
        once $rem.add: 'One more thing, bruh', :10in;
        done unless $rem.waiting;
    }
```

# DESCRIPTION

You ask the class to remind you with stuff, tagged with an optional name and
location. When the time comes, the class will emit the reminder to a `Supply`.
The reminders are stored in an SQLite database, so even if you close the
program, you will still get your reminders the next time you fire it up.

# METHODS

## `new`

# TESTING

To run the full test suite, set `EXTENDED_TESTING` environmental variable to `1`

# LIMITATIONS

Currently, trying to use the same database file from multiple programs or multiple
`Reminders` instances might have issues due to race conditions.

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
