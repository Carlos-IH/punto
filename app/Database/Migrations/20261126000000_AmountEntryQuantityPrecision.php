<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

/**
 * Preserve enough quantity precision for amount/weight sales to match the
 * requested currency amount after converting it to a fractional quantity.
 */
class AmountEntryQuantityPrecision extends Migration
{
    public function up(): void
    {
        foreach ([
            ['item_quantities', 'quantity'],
            ['inventory', 'trans_inventory'],
            ['item_kit_items', 'quantity'],
            ['receivings_items', 'quantity_purchased'],
            ['sales_items', 'quantity_purchased'],
            ['sales_suspended_items', 'quantity_purchased'],
        ] as [$table, $column]) {
            $qualifiedTable = $this->db->escapeIdentifiers($this->db->prefixTable($table));
            $this->db->query("ALTER TABLE $qualifiedTable MODIFY COLUMN `$column` decimal(15,6) NOT NULL DEFAULT '0'");
        }
    }

    public function down(): void
    {
        // Reducing precision could silently change existing fractional sales.
    }
}
