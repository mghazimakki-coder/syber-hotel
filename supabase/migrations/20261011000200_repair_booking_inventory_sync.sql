-- Reinstall the existing transactional inventory trigger and repair status
-- drift for rooms and apartments without overriding maintenance state.
drop trigger if exists bookings_sync_inventory_status on public.bookings;
create trigger bookings_sync_inventory_status
  after update of status on public.bookings
  for each row execute function public.sync_booking_inventory_status();

update public.rooms r
set status = case
  when exists (
    select 1
    from public.bookings b
    where b.room_id = r.id
      and b.hotel_id = r.hotel_id
      and b.status = 'checked_in'
  ) then 'occupied'
  else 'available'
end
where r.status in ('available', 'occupied')
  and r.status is distinct from case
    when exists (
      select 1
      from public.bookings b
      where b.room_id = r.id
        and b.hotel_id = r.hotel_id
        and b.status = 'checked_in'
    ) then 'occupied'
    else 'available'
  end;

update public.apartments a
set status = case
  when exists (
    select 1
    from public.bookings b
    where b.apartment_id = a.id
      and b.hotel_id = a.hotel_id
      and b.status = 'checked_in'
  ) then 'occupied'
  else 'available'
end
where a.status in ('available', 'occupied')
  and a.status is distinct from case
    when exists (
      select 1
      from public.bookings b
      where b.apartment_id = a.id
        and b.hotel_id = a.hotel_id
        and b.status = 'checked_in'
    ) then 'occupied'
    else 'available'
  end;
