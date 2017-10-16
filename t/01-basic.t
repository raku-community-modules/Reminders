use lib <lib>;
use Testo;
use Test::When <extended>;
use Temp::Path;
plan 1;
use Reminders;

my Reminders $rem .= new: :db-file(make-temp-path);
$rem.add: 'one', :2in;
$rem.add: 'two', :4in;
$rem.add: 'three', :when(now+6), :who<Zoffix>, :where<#perl6>;

my @reminders;
react whenever $rem {
    @reminders.push: "Reminder: $^reminder";
    # once $rem.add: 'four', :6in;
    # done unless $rem.waiting;
}

is @reminders, (), 'all reminders are correct';
