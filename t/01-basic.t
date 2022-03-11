use lib <lib>;
use Test;
use Temp::Path;
plan 1;
use Reminders;

my Reminders $rem .= new: :db-file(make-temp-path);
$rem.add: 'one', :2in;
$rem.add: 'two', :4in;
$rem.add: 'three', :when(now+6), :who<Zoffix>, :where<#perl6>;

my @reminders;
react whenever $rem {
    say "Reacting $rem";
    @reminders.push: "Reminder: $^reminder";
    once {
        say "Once";
        $rem.add: 'four', :6in;
        $rem.done;
    }
}

is-deeply @reminders,  [«"Reminder: one"  "Reminder: two"
    "Reminder: Zoffix@#perl6 three" "Reminder: four"»], 'all reminders are correct';
