<?php
//    function hypo()


/**
 *    Mike Bommarito's version.
 *    Compute n-dimensional hyotheneuse.
 *
function hypot() {
    $s = 0;
    foreach (func_get_args() as $d) {
        if (is_numeric($d)) {
            $s += pow($d, 2);
        } else {
            throw new PHPExcel_Calculation_Exception(JAMAError(ARGUMENT_TYPE_EXCEPTION));
        }
    }
    return sqrt($s);
}
*/
