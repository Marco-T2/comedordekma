<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('fingerprints', function (Blueprint $t) {
            $t->unsignedBigInteger('card_id')->after('id');
            $t->string('finger', 20)->nullable()->after('card_id');   // ej: right_index
            $t->longText('template_base64')->after('finger');
            $t->boolean('activo')->default(true)->after('template_base64');

            $t->index(['card_id', 'activo']);
            $t->index('updated_at');
            $t->foreign('card_id')->references('id')->on('cards')->onDelete('cascade');
            $t->unique(['card_id', 'finger']);
        });
    }

    public function down(): void
    {
        Schema::table('fingerprints', function (Blueprint $t) {
            $t->dropUnique(['card_id', 'finger']);
            $t->dropForeign(['card_id']);
            $t->dropIndex(['card_id', 'activo']);
            $t->dropIndex(['updated_at']);
            $t->dropColumn(['card_id', 'finger', 'template_base64', 'activo']);
        });
    }
};
