/*
	__schema__   The schema the results are stored in.
	__partner__  The partner that should be added.
	__login__    The user/login the partner should be added for.
	            
	This statement selects the non-admin user/login that
	already has the supplied partner name if __login__
	isn't an admin user/login themselves.
	
	If the partner doesn't exist yet, or it only exists for
	admin users/logins, or __login__ is an admin user/login,
	the result is empty.
*/

with admin_users as (
  select login
  from __schema__.known_partners
  where partner = '__all__' -- Thats a constant in the table, don't replace it!
),
non_admin_users as (
  select distinct login
  from __schema__.known_partners
  where login not in (select login from admin_users)
)
select login
from __schema__.known_partners
join non_admin_users using(login)
where partner = '__partner__'
and '__login__' not in (select login from admin_users);