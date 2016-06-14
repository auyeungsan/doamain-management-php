<?php

$hosts = $_GET['domain'];
$ex_date = $_GET['ex_date'];
$date_left = $_GET['date_left'];
$registar = $_GET['registar'];

if(empty($hosts)){
	echo ' ';
}else{
	if(!empty($ex_date)){
		$result = shell_exec("./domain-check.sh -d $hosts|awk 'NR==4'| cut -d ' ' -f39");
		#echo "/var/www/html/domain-check.sh -d $hosts|awk 'NR==4'| cut -d ' ' -f42";
		echo $result;
	}elseif(!empty($date_left)){
                $result = shell_exec("./domain-check.sh -d $hosts|awk 'NR==4'| cut -d ' ' -f42");
                #echo "/var/www/html/domain-check.sh -d $hosts|awk 'NR==4'| cut -d ' ' -f42";
                echo $result;
	
	}elseif(!empty($registar)){
		$result = shell_exec("./domain-check.sh -d $hosts|awk 'NR==4'| cut -d ' ' -f26");
                #echo "/var/www/html/domain-check.sh -d $hosts|awk 'NR==4'| cut -d ' ' -f42";
                echo $result;
	}else{
		echo ' ';
	}
}


?>
