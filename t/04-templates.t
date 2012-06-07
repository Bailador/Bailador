use Test;
use Bailador;
use Bailador::Test;

plan 1;

get '/' => sub { template 't/templates/simple.tt', 'bar' }

response-content-is 'GET', '/', "a happy bar\n";
