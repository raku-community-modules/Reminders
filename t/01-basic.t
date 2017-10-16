use lib <lib>;
use Test;
use Test::When <extended>;
use Temp::Path;

use Reminders;

my Reminders $rem .= new: :db-file(make-temp-path);
$rem.add: 'go home', when => DateTime.now.later: :9hours;
say $rem.all;
