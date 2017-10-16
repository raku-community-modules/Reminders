use OO::Monitors;
unit monitor Reminders;
use DBIish;

has $!db;
has $!supplier = Supplier::Preserving.new;

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
}

submethod TWEAK (IO() :$db-file = 'reminders.sqlite.db') {
    my $deploy = $db-file.e.not;
    $!db = DBIish.connect: 'SQLite', :database($db-file), :RaiseError;
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
    self.all
}

method add (
            Str:D  \what,
            Str:D  :$who   = 'N/A',
            Str:D  :$where = 'N/A',
    Instant(Any:D) :$when! where DateTime|Instant
) {
    $!db.do: ｢
        INSERT INTO reminders ("who", "what", "where", "when", "created")
            VALUES (?, ?, ?, ?, ?)
    ｣, $who, what, $where, $when.to-posix.head, time;
    for self.all -> $rem {
        if now - .when < 10            { $!supplier.emit: $rem.mark-seen }
        else { Promise.at(.when).then: { $!supplier.emit: $rem.mark-seen } }
    }
}

method all (:$all) {
    with $!db.prepare: ｢SELECT * FROM reminders ｣
      ~ (｢WHERE seen == 0｣ unless $all) ~ ｢ ORDER BY "created" DESC｣
    {
        .execute;
        # https://github.com/perl6/DBIish/issues/93
        eager .allrows(:array-of-hash).map: {
            Rem.new(
                :id(.<id>), :who(.<who>), :what(.<what>), :where(.<where>),
                :when(Instant.from-posix: .<when>),
                :created(Instant.from-posix: .<created>),
            )!Rem::rem(self)
        };
    }
}

method mark-seen (Rem $rem) {
    $!db.do: ｢UPDATE reminders SET seen = 1 WHERE id = ?｣, $rem.id;
    $rem;
}

method Supply { $!supplier.Supply }
