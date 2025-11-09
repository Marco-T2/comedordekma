<?php

use Illuminate\Support\Facades\Route;
use App\Models\Card;
use App\Http\Controllers\BiometricController;

Route::get('/validar/{card}', function (string $card) {
    $reg = Card::where('code', $card)->where('activo', true)->first();

    if (!$reg) {
        return response()->json(['ok' => false, 'msg' => 'Tarjeta no válida'], 404);
    }

    return response()->json([
        'ok'     => true,
        'card'   => $reg->code,
        'nombre' => $reg->nombre,
        'tipo'   => $reg->tipo,
    ]);
});

Route::get('/fp/templates', [BiometricController::class, 'templates']);
Route::get('/validar-card/{cardId}', [BiometricController::class, 'validarCard']);
