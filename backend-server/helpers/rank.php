<?php
// helpers/rank.php

function calculateRank(int $rep): string {
    if ($rep >= 1000) return 'Cyber Commander';
    if ($rep >= 500)  return 'Security Expert';
    if ($rep >= 250)  return 'Security Analyst';
    return 'Recruit';
}
?>
