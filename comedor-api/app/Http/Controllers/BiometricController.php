<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Fingerprint;
use App\Models\Card;

class BiometricController extends Controller
{
    // GET /api/fp/templates?since=ISO8601
    public function templates(Request $req)
    {
        $q = Fingerprint::where('activo', 1);
        if ($req->query('since')) {
            $q->where('updated_at', '>=', $req->query('since'));
        }
        $rows = $q->get();

        $out = $rows->map(fn($f) => [
            'cardId'     => $f->card_id,
            'finger'     => $f->finger,
            'template'   => $f->template_base64,
            'updated_at' => optional($f->updated_at)->toIso8601String(),
        ]);

        return response()->json(['ok' => true, 'templates' => $out]);
    }

    // GET /api/validar-card/{cardId}
    public function validarCard($cardId)
    {
        $c = Card::find($cardId);
        if (!$c)        return response()->json(['ok' => false, 'msg' => 'Card no existe'], 404);
        if (!$c->activo) return response()->json(['ok' => false, 'msg' => 'Card inactiva']);

        return response()->json([
            'ok'     => true,
            'nombre' => $c->nombre,
            'tipo'   => $c->tipo,
        ]);
    }
}
