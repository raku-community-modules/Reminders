use OO::Monitors;
unit monitor Reminders;
use DBIish;

has $!db;
has $!supplier = Supplier::Preserving.new;
has $!waiting = 0;
has $!done = False;

class Rem {
    trusts Reminders;
    has      Int:D $.id    is required;
    has      Str:D $.what  is required;
    has      Str:D $.who   is required;
    has      Str:D $.where is required;
    has  Instant:D $.when  is required;
    has     Bool:D $.seen  = False;
    has Reminders  $!rem;
    method !rem($!rem) { self }
    method mark-seen { $!seen = True; $!rem.mark-seen: self }
    method Str {
        my $who-str = $!who ~ ("@" if $!who or $!where) ~ $!where;
        "{"$who-str " if $who-str}$!what"
    }
    method gist { self.Str }
}

submethod TWEAK (IO() :$db-file = 'reminders.sqlite.db') {
    my $deploy = $db-file.e.not;
    $!db = DBIish.connect: 'SQLite', :database($db-file.absolute), :RaiseError;
    $deploy and $!db.do: ｢
        CREATE TABLE reminders (
            "id"        INTEGER PRIMARY KEY,
            "who"       TEXT NOT NULL,
            "what"      TEXT NOT NULL,
            "where"     TEXT NOT NULL,
            "when"      TEXT NOT NULL,
            "created"   INTEGER UNSIGNED NOT NULL,
            "seen"      INTEGER UNSIGNED NOT NULL DEFAULT 0
        )
    ｣;
    for self.all -> $rem {
        if $rem.when - now < 6 { $!supplier.emit: $rem.mark-seen }
        else {
            $!waiting++;
            Promise.at($rem.when).then: {
                $!supplier.emit: $rem.mark-seen;
                $!supplier.done if $!done and not --$!waiting;
            }
        }
    }
}

multi method add (Int:D :$in, |c) { self.add: |c, :when(now + $in) }
multi method add (
            Str:D  \what,
            Str:D  :$who   = '',
            Str:D  :$where = '',
    Instant(Any:D) :$when! where DateTime|Instant
) {
    $!done and die 'Cannot add more reminders to Reminders object that was .done';
    $!db.do: ｢
        INSERT INTO reminders ("who", "what", "where", "when", "created")
            VALUES (?, ?, ?, ?, ?)
    ｣, $who, what, $where, $when.to-posix.head, time;

    my $rem = do with $!db.prepare:
        ｢SELECT * FROM reminders WHERE id = last_insert_rowid()｣
    {
        LEAVE .finish; .execute;
        with .fetchrow-hash {
            Rem.new(
                :id(.<id>.Int), :who(.<who>), :what(.<what>), :where(.<where>),
                :when(Instant.from-posix: .<when>),
                :created(Instant.from-posix: .<created>),
            )!Rem::rem(self)
        }
    };
    if $rem.when - now < 6 { $!supplier.emit: $rem.mark-seen }
    else {
        $!waiting++;
        Promise.at($rem.when).then: {
            $!supplier.emit: $rem.mark-seen;
            $!supplier.done if $!done and not --$!waiting;
        }
    }
}

method all (:$all) {
    with $!db.prepare: ｢SELECT * FROM reminders ｣
      ~ (｢WHERE seen == 0｣ unless $all) ~ ｢ ORDER BY "created" DESC｣
    {
        LEAVE .finish; .execute;
        # https://github.com/perl6/DBIish/issues/93
        eager .allrows(:array-of-hash).map: {
            Rem.new(
                :id(.<id>.Int), :who(.<who>), :what(.<what>), :where(.<where>),
                :when(Instant.from-posix: .<when>),
                :created(Instant.from-posix: .<created>),
            )!Rem::rem(self)
        };
    }
}

method done { $!waiting ?? ($!done = True) !! $!supplier.done }

method mark-seen (Rem $rem) {
    $!db.do: ｢UPDATE reminders SET seen = 1 WHERE id = ?｣, $rem.id;
    $rem;
}

method Supply { $!supplier.Supply }
