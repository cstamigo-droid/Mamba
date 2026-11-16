'use strict';
// node --require tools/asistente/lua51/shim.js ...  con LUA=lupa51:
// las llamadas a "lupa51" se corren con python + lupa (Lua 5.1). Solo para pruebas.
const cp = require('node:child_process');
const path = require('node:path');
const real = cp.spawnSync;
const PY = process.env.MAMBA_PYTHON || 'python';
const SCRIPT = path.join(__dirname, 'lua51.py');
cp.spawnSync = function (bin, args, opts) {
	if (bin === 'lupa51') return real.call(this, PY, ['-I', SCRIPT, ...(args || [])], opts);
	return real.apply(this, arguments);
};
