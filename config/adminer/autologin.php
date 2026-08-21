<?php

class AdminerAutologin extends Adminer\Plugin
{
    private const SUPPORTED_DRIVERS = [
        'server' => 'MySQL',
        'sqlite' => 'SQLite 3',
        'sqlite2' => 'SQLite 2',
        'pgsql' => 'PostgreSQL',
        'oracle' => 'Oracle',
        'mssql' => 'MS SQL',
        'mongo' => 'MongoDB',
        'elastic' => 'Elasticsearch',
    ];

    private array $auth = [];

    public function __construct()
    {
        $driver = getenv('ADMINER_DRIVER') ?: 'server';
        
        if (!isset(self::SUPPORTED_DRIVERS[$driver])) {
            $driver = 'server';
        }

        $this->auth = [
            'driver' => $driver,
            'server' => getenv('ADMINER_SERVER') ?: '',
            'username' => getenv('ADMINER_USERNAME') ?: '',
            'password' => getenv('ADMINER_PASSWORD') ?: '',
            'db' => getenv('ADMINER_DB') ?: '',
        ];
    }

    public function loginForm()
    {
        if (empty($this->auth['server']) || empty($this->auth['username'])) {
            echo '<div style="padding: 20px; background: #fff3cd; border: 1px solid #ffc107; border-radius: 4px; margin-bottom: 20px;">';
            echo '<strong>Auto-login aborted.</strong><br><br>';
            echo 'Missing required environment variables. ADMINER_SERVER and ADMINER_USERNAME must be set.';
            echo '</div>';
            return null;
        }

        if (isset($_POST['autologin_attempt'])) {
            echo '<div style="padding: 20px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px; color: #721c24; margin-bottom: 20px;">';
            echo '<strong>Auto-login failed.</strong><br><br>';
            echo 'Adminer executed the login request, but the database connection was rejected.<br><br>';
            echo '<strong>Diagnostics - Attempted Configuration:</strong><br>';
            echo 'Driver: <strong>' . htmlspecialchars($this->auth['driver'], ENT_QUOTES) . '</strong><br>';
            echo 'Server: <strong>' . htmlspecialchars($this->auth['server'], ENT_QUOTES) . '</strong><br>';
            echo 'Username: <strong>' . htmlspecialchars($this->auth['username'], ENT_QUOTES) . '</strong><br>';
            echo 'Database: <strong>' . htmlspecialchars($this->auth['db'], ENT_QUOTES) . '</strong><br>';
            echo '</div>';
            return null;
        }

        echo "<table cellspacing='0' style='display: none;'>\n";
        echo "<tr><th>Driver<td><select name='auth[driver]'><option value='" . htmlspecialchars($this->auth['driver'], ENT_QUOTES) . "' selected></option></select>\n";
        echo "<tr><th>Server<td><input name='auth[server]' value='" . htmlspecialchars($this->auth['server'], ENT_QUOTES) . "'>\n";
        echo "<tr><th>Username<td><input name='auth[username]' id='username' value='" . htmlspecialchars($this->auth['username'], ENT_QUOTES) . "'>\n";
        echo "<tr><th>Password<td><input type='password' name='auth[password]' value='" . htmlspecialchars($this->auth['password'], ENT_QUOTES) . "' autocomplete='current-password'>\n";
        echo "<tr><th>Database<td><input name='auth[db]' value='" . htmlspecialchars($this->auth['db'], ENT_QUOTES) . "'>\n";
        echo "</table>\n";
        
        echo '<input type="hidden" name="autologin_attempt" value="1">';
        
        $nonce = '';
        if (function_exists('nonce')) {
            $nonce = nonce();
        } elseif (function_exists('Adminer\nonce')) {
            $nonce = \Adminer\nonce();
        } elseif (function_exists('get_nonce')) {
            $nonce = ' nonce="' . get_nonce() . '"';
        } elseif (function_exists('Adminer\get_nonce')) {
            $nonce = ' nonce="' . \Adminer\get_nonce() . '"';
        }

        $js = "window.addEventListener('DOMContentLoaded', function() { document.forms[0].submit(); });";
        echo "<script{$nonce}>{$js}</script>";
        echo '<div style="padding: 20px;">Executing auto-login...</div>';

        return true;
    }
}

return new AdminerAutologin();