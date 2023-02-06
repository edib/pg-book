<?php
for ($i=0; $i<10; $i++) {
    // open ten processes
    for ($j = 0; $j < 10; $j++) {
        $pipe[$j] = popen('bench2.php', 'w');
    }

    // wait for them to finish
    for ($j = 0; $j < 10; ++$j) {
        pclose($pipe[$j]);
    }
}