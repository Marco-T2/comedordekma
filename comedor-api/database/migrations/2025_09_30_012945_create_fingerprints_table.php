<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('fingerprints', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('card_id');
            $t->string('finger', 20)->nullable();      // ej: right_index
            $t->longText('template_base64');           // huella en base64
            $t->boolean('activo')->default(true);
            $t->timestamps();

            $t->index(['card_id', 'activo']);
            $t->index('updated_at');
            $t->foreign('card_id')->references('id')->on('cards')->onDelete('cascade');
            $t->unique(['card_id', 'finger']);          // evita duplicar el mismo dedo
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('fingerprints');
    }
};
