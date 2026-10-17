-- Give receptionists access only to records associated with their assigned hotel.
-- Hotel assignment and role are always resolved from the authenticated profile.

drop policy if exists "Receptionists are restricted to their hotel bookings"
  on public.bookings;
create policy "Receptionists are restricted to their hotel bookings"
  on public.bookings
  as restrictive
  for all
  to authenticated
  using (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or hotel_id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists are restricted to their hotel rooms"
  on public.rooms;
create policy "Receptionists are restricted to their hotel rooms"
  on public.rooms
  as restrictive
  for all
  to authenticated
  using (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or hotel_id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists are restricted to their hotel apartments"
  on public.apartments;
create policy "Receptionists are restricted to their hotel apartments"
  on public.apartments
  as restrictive
  for all
  to authenticated
  using (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or hotel_id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists are restricted to their hotel record"
  on public.hotels;
create policy "Receptionists are restricted to their hotel record"
  on public.hotels
  as restrictive
  for all
  to authenticated
  using (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or id = public.get_my_hotel()
  );

drop policy if exists "Receptionists are restricted to their hotel customers"
  on public.profiles;
create policy "Receptionists are restricted to their hotel customers"
  on public.profiles
  as restrictive
  for select
  to authenticated
  using (
    public.get_my_role() is distinct from 'receptionist'::public.user_role
    or id = (select auth.uid())
    or exists (
      select 1
      from public.bookings
      where bookings.user_id = profiles.id
        and bookings.hotel_id = public.get_my_hotel()
    )
  );

-- Extend the restrictive SELECT guard from the earlier booking policy script,
-- but only when that guard is already installed.
do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'bookings'
      and policyname = 'bookings_select_scope_guard'
      and cmd = 'SELECT'
      and permissive = 'RESTRICTIVE'
  ) then
    execute 'drop policy bookings_select_scope_guard on public.bookings';
    execute $policy$
      create policy bookings_select_scope_guard
        on public.bookings
        as restrictive
        for select
        to public
        using (
          (
            public.get_my_role() = 'customer'::public.user_role
            and user_id = (select auth.uid())
          )
          or (
            public.get_my_role() = 'manager'::public.user_role
            and hotel_id = public.get_my_hotel()
          )
          or (
            public.get_my_role() = 'receptionist'::public.user_role
            and hotel_id = public.get_my_hotel()
          )
        )
    $policy$;
  end if;
end
$$;

drop policy if exists "Receptionists can view bookings for their hotel"
  on public.bookings;
create policy "Receptionists can view bookings for their hotel"
  on public.bookings
  for select
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can update bookings for their hotel"
  on public.bookings;
create policy "Receptionists can update bookings for their hotel"
  on public.bookings
  for update
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can view rooms for their hotel"
  on public.rooms;
create policy "Receptionists can view rooms for their hotel"
  on public.rooms
  for select
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can update rooms for their hotel"
  on public.rooms;
create policy "Receptionists can update rooms for their hotel"
  on public.rooms
  for update
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can view apartments for their hotel"
  on public.apartments;
create policy "Receptionists can view apartments for their hotel"
  on public.apartments
  for select
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can update apartments for their hotel"
  on public.apartments;
create policy "Receptionists can update apartments for their hotel"
  on public.apartments
  for update
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  )
  with check (
    public.get_my_role() = 'receptionist'::public.user_role
    and hotel_id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can view their hotel"
  on public.hotels;
create policy "Receptionists can view their hotel"
  on public.hotels
  for select
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and id = public.get_my_hotel()
  );

drop policy if exists "Receptionists can view profiles of their hotel customers"
  on public.profiles;
create policy "Receptionists can view profiles of their hotel customers"
  on public.profiles
  for select
  to authenticated
  using (
    public.get_my_role() = 'receptionist'::public.user_role
    and exists (
      select 1
      from public.bookings
      where bookings.user_id = profiles.id
        and bookings.hotel_id = public.get_my_hotel()
    )
  );
