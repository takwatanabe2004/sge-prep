function hostname = tak_get_host
[trash,host] = system('hostname');
hostname = host(1:end-1);
