<?php

use Illuminate\Support\Facades\Route;
use App\Models\Card;
use App\Http\Controllers\BiometricController;

Route::get('/validar/{card}', function (string $card) {
    // Allow validating by physical card code or by RFC code (5-digit assigned code)
    $reg = Card::where(function($q) use ($card){
        $q->where('code', $card)
          ->orWhere('code_rfc', $card);
    })->where('activo', true)->first();

    if (!$reg) {
        return response()->json(['ok' => false, 'msg' => 'Tarjeta no válida'], 404);
    }

    return response()->json([
        'ok'     => true,
        'card'   => $reg->code,
        'code_rfc' => $reg->code_rfc,
        'nombre' => $reg->nombre,
        'tipo'   => $reg->tipo,
    ]);
});

// Generate a new unique 5-digit RFC code for cards (POST /api/generate-code)
Route::post('/generate-code', function(){
    // simple loop to allocate a unique 5-digit code
    do {
        $code = str_pad((string)random_int(0, 99999), 5, '0', STR_PAD_LEFT);
        $exists = Card::where('code_rfc', $code)->exists();
    } while($exists);

    return response()->json(['ok' => true, 'code' => $code]);
});

Route::get('/fp/templates', [BiometricController::class, 'templates']);
Route::get('/validar-card/{cardId}', [BiometricController::class, 'validarCard']);
