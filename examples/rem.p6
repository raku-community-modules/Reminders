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
