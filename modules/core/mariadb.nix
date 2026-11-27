{ pkgs, ... }:

{
  # MariaDB Database Service (Disabled on startup)
  # When needed, set enable = true to start local MariaDB daemon.
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
    settings = {
      mysqld = {
        bind-address = "127.0.0.1";
        port = 3306;
      };
    };
  };
}
