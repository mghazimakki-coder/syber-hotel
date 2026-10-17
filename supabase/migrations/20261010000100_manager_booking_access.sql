-- Managers may read all bookings for their assigned hotel, regardless of who booked.
drop policy if exists "Managers can view bookings for their hotel"
  on public.bookings;

create policy "Managers can view bookings for their hotel"
  on public.bookings
  for select
  to authenticated
  using (
    hotel_id = public.get_my_hotel()
    and public.get_my_role() = 'manager'
  );

-- Expose only profiles that are customers of the manager's own hotel.
drop policy if exists "Managers can view profiles of their hotel customers"
  on public.profiles;

create policy "Managers can view profiles of their hotel customers"
  on public.profiles
  for select
  to authenticated
  using (
    public.get_my_role() = 'manager'
    and exists (
      select 1
      from public.bookings
      where bookings.user_id = profiles.id
        and bookings.hotel_id = public.get_my_hotel()
    )
  );