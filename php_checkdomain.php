<?php

$hosts = $_GET['domain'];
$type = $_GET['type'];
#$ex_date = $_GET['ex_date'];
#$date_left = $_GET['date_left'];
#$registar = $_GET['registar'];
#$ex_var = $_GET['ex_var'];
$g_log_path = '/tmp/game_check';
$ng_log_path = '/tmp/game_check';


if(isset($_GET['ex_date'])){
	$ex_date = $_GET['ex_date'];
}

if(isset($_GET['date_left'])){
	$date_left = $_GET['date_left'];
}

if(isset($_GET['registar'])){
	$registar = $_GET['registar'];
}

if(isset($_GET['ex_var'])){
	$ex_var = $_GET['ex_var'];
}



if(!empty($hosts) && !empty($type)){


	if($type == 'game'){
	
		if(!empty($ex_date)){
			$result = shell_exec("grep -w $hosts $g_log_path|awk -F' ' '{ print $4 }'");
			echo $result;

		}
	
		if(!empty($date_left)){
                	$result = shell_exec("grep -w $hosts $g_log_path|awk -F' ' '{ print $5 }'");
                	echo $result;
	
		}
	
		if(!empty($registar)){
			$result = shell_exec("grep -w $hosts $g_log_path|awk -F' ' '{ print $2 }'");
                	echo $result;
		}
	
		if(!empty($ex_var)){
			$result = shell_exec("grep -w $hosts $g_log_path|awk -F' ' '{ print $5 }'");
						
			$result = trim($result);
		
			if(!eregi("^[0-9]+$",$result)){
				echo 'unknow';
				#echo $result;
				exit;	
			}elseif(empty($result)){
				echo 'unknow';
				exit;	
			}elseif($result =='whois'){
				echo 'unknow';
				exit;	
			}	
	
			$result = intval($result);

			if($result < 7){

				echo 'critical';
				#echo $result;
			}elseif($result <= 30){

				echo 'warning';
				#echo $result;
			}elseif($result > 30){

				echo 'normal';
				#echo $result;

			}

		}
	
	}else{
		if(!empty($ex_date)){
                        $result = shell_exec("grep -w $hosts $ng_log_path|awk -F' ' '{ print $4 }'");
                        echo $result;

                }
        
                if(!empty($date_left)){
                        $result = shell_exec("grep -w $hosts $ng_log_path|awk -F' ' '{ print $5 }'");
                        echo $result;
        
                }
        
                if(!empty($registar)){
                        $result = shell_exec("grep -w $hosts $ng_log_path|awk -F' ' '{ print $2 }'");
                        echo $result;
                }
        
                if(!empty($ex_var)){
                        $result = shell_exec("grep -w $hosts $ng_log_path|awk -F' ' '{ print $5 }'");
                
			$result = trim($result);

                        if(!eregi("^[0-9]+$",$result)){
                                echo 'unknow';
                                exit;
                        }elseif(empty($result)){
                                echo 'unknow';
                                exit;
                        }elseif($result == 'whois'){
                                echo 'unknow';
                                exit;
                        }
        
                        $result = intval($result);

                        if($result < 7){

                                echo 'critical';

                        }elseif($result <= 30){

                                echo 'warning';

                        }elseif($result > 30){

                                echo 'normal';

                        }

                }

	}	

}

?>
