<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Fingerprint extends Model
{
    protected $table = 'fingerprints';
    protected $fillable = ['card_id', 'finger', 'template_base64', 'activo'];

    public function card()
    {
        return $this->belongsTo(\App\Models\Card::class);
    }
}
