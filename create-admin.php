<?php
// First boot only: create the administrator from ADMIN_EMAIL / ADMIN_PASSWORD and close
// public registration, so the first visitor of a fresh deploy can't claim the instance.
// Later boots do nothing (the admin manages users and passwords in the app).
require '/srv/vendor/autoload.php';
$app = require '/srv/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Facades\Settings;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

if (User::count() > 0) {
    fwrite(STDOUT, "railway: users already exist, skipping admin creation\n");
    exit(0);
}

$email = trim((string) getenv('ADMIN_EMAIL'));
$password = (string) getenv('ADMIN_PASSWORD');
$name = trim((string) getenv('ADMIN_NAME')) ?: 'admin';

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 8) {
    fwrite(STDERR, "railway: set ADMIN_EMAIL (a valid email) and ADMIN_PASSWORD (8+ characters) to create the first admin\n");
    exit(1);
}

$user = User::create(['name' => $name, 'email' => $email, 'password' => Hash::make($password)]);
$user->promoteToAdministrator();
$user->save();
Settings::set('disableRegistration', true);

fwrite(STDOUT, sprintf("railway: created administrator #%d (%s) and disabled public registration\n", $user->id, $email));
