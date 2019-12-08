#/bin/sh

sleep 30

while ! php bin/console doctrine:database:create --if-not-exists --verbose --no-ansi --no-interaction; do
	sleep 10
done

php bin/console doctrine:schema:update --force
php bin/console doctrine:fixtures:load
