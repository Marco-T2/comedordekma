<?php

use Illuminate\Support\Facades\Route;
use App\Models\Card;
use App\Http\Controllers\BiometricController;
use Illuminate\Http\Request;

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
    // simple loop to allocate a unique 5-digit code for the `code` field
    do {
        $code = str_pad((string)random_int(0, 99999), 5, '0', STR_PAD_LEFT);
        $exists = Card::where('code', $code)->exists();
    } while($exists);

    return response()->json(['ok' => true, 'code' => $code]);
});

Route::get('/fp/templates', [BiometricController::class, 'templates']);
Route::get('/validar-card/{cardId}', [BiometricController::class, 'validarCard']);

// Minimal CRUD for cards to support the simple admin UI
Route::get('/cards', function(){
    return Card::orderBy('id', 'desc')->get();
});

Route::get('/cards/{id}', function($id){
    $c = Card::find($id);
    if(!$c) return response()->json(['ok'=>false,'msg'=>'No encontrado'],404);
    return $c;
});

Route::post('/cards', function(Request $request){
    // Now: `code` is the 5-digit auto-generated (keyboard) code.
    // `code_rfc` is the optional physical card identifier.
    $data = $request->only(['nombre','tipo','code','code_rfc']);
    if(empty($data['nombre'])){
        return response()->json(['ok'=>false,'msg'=>'El nombre es requerido'],422);
    }
    $tipo = in_array($data['tipo'] ?? '', ['normal','administracion','Visitantes']) ? $data['tipo'] : 'normal';

    // Generate a unique 5-digit code for `code` if not provided
    if(empty($data['code'])){
        do {
            $gen = str_pad((string)random_int(0, 99999), 5, '0', STR_PAD_LEFT);
            $exists = Card::where('code', $gen)->exists();
        } while($exists);
        $data['code'] = $gen;
    } else {
        // ensure provided code is unique (and plausibly 5 digits)
        if(Card::where('code', $data['code'])->exists()){
            return response()->json(['ok'=>false,'msg'=>'Código ya existe'],409);
        }
    }

    // If code_rfc provided, ensure uniqueness as well
    if(!empty($data['code_rfc'])){
        if(Card::where('code_rfc', $data['code_rfc'])->exists()){
            return response()->json(['ok'=>false,'msg'=>'Código de tarjeta (code_rfc) ya existe'],409);
        }
    }

    $card = Card::create([
        'code' => $data['code'],
        'code_rfc' => $data['code_rfc'] ?? null,
        'nombre' => $data['nombre'],
        'tipo' => $tipo,
        'activo' => 1,
    ]);

    return response()->json(['ok'=>true,'card'=>$card],201);
});

Route::put('/cards/{id}', function(Request $request, $id){
    $card = Card::find($id);
    if(!$card) return response()->json(['ok'=>false,'msg'=>'No encontrado'],404);
    $data = $request->only(['nombre','tipo','code']);
    if(isset($data['nombre'])) $card->nombre = $data['nombre'];
    if(isset($data['tipo']) && in_array($data['tipo'], ['normal','administracion','Visitantes'])) $card->tipo = $data['tipo'];
    if(isset($data['code'])) $card->code = $data['code'];
    $card->save();
    return response()->json(['ok'=>true,'card'=>$card]);
});

Route::delete('/cards/{id}', function($id){
    $card = Card::find($id);
    if(!$card) return response()->json(['ok'=>false,'msg'=>'No encontrado'],404);
    // Soft-delete: marcar como inactivo en vez de borrar físicamente
    $card->activo = 0;
    $card->save();
    return response()->json(['ok'=>true]);
});
