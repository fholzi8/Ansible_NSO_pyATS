<?php

$watchman1 = "http://demuc-srvacdao1/watchman/";
$watchman2 = "http://demuc-srvacdao2/watchman/";

/*pruefe welcher watchman gerade activ*/

$watchman_active = $watchman2;

/*lade statuspage von aktiven watchman*/
$content = file_get_contents ($watchman2);

/*prüfe ob SYS1.CTI1 laeuft*/
/*teststring fuer cti1*/
$cti1 = 'alt="OK"/></td><td>SYS1.CTI1';

if (strpos ($content,$cti1) > 0) {
	echo "SYS1.CTI1 OK\n";
}
else {
	echo "SYS1.CTI1 ERROR\n";
}

/*pruefe ob SYS2.CTI1 laeuft*/
/*teststring fuer cti1*/
$cti2 = 'alt="OK"/></td><td>SYS2.CTI1';

if (strpos ($content,$cti2) > 0) {
        echo "SYS2.CTI1 OK\n";
}
else {
        echo "SYS2.CTI1 ERROR\n";
}


?>
