-- Sample Transport Companies
INSERT INTO transport_companies (company_name, central_phone, rating, is_active) VALUES
('افغان ګو اکسپرس', '+93-700-123456', 4.50, true),
('خط کابل-هرات', '+93-700-234567', 4.20, true),
('ستاره شمال', '+93-700-345678', 4.00, true),
('وی آی پی اکسپرس', '+93-700-456789', 4.80, true);

-- Sample Buses (40 seats each, mixed standard/VIP)
INSERT INTO buses (company_id, plate_number, bus_type, total_seats, has_ac, has_meal, has_sleeper, driver_name, driver_phone) VALUES
((SELECT id FROM transport_companies WHERE company_name = 'افغان ګو اکسپرس'), 'کابل-۱۲۳۴', 'vip', 40, true, true, true, 'احmadشاه', '+93-701-111111'),
((SELECT id FROM transport_companies WHERE company_name = 'افغان ګو اکسپرس'), 'کابل-۵۶۷۸', 'standard', 40, true, false, false, 'عمرخان', '+93-701-222222'),
((SELECT id FROM transport_companies WHERE company_name = 'خط کابل-هرات'), 'هرات-۱۱۱۱', 'standard', 40, true, false, false, 'محمدرحیم', '+93-702-333333'),
((SELECT id FROM transport_companies WHERE company_name = 'خط کابل-هرات'), 'هرات-۲۲۲۲', 'vip', 40, true, true, true, 'نوراحمد', '+93-702-444444'),
((SELECT id FROM transport_companies WHERE company_name = 'ستاره شمال'), 'مزار-۱۱۱۱', 'standard', 40, true, false, false, 'عبدالله', '+93-703-555555'),
((SELECT id FROM transport_companies WHERE company_name = 'ستاره شمال'), 'مزار-۲۲۲۲', 'vip', 40, true, true, true, 'فیروز', '+93-703-666666'),
((SELECT id FROM transport_companies WHERE company_name = 'وی آی پی اکسپرس'), 'کابل-۹۹۹۹', 'vip', 40, true, true, true, 'خالد', '+93-704-777777'),
((SELECT id FROM transport_companies WHERE company_name = 'وی آی پی اکسپرس'), 'کندهار-۱۱۱۱', 'vip', 40, true, true, true, 'حاجی محمد', '+93-704-888888');

-- Sample Trips (tomorrow and day after tomorrow)
INSERT INTO trips (bus_id, company_id, origin, destination, departure_at, arrival_at, normal_price, vip_price, available_seats, status) VALUES
-- Kabul → Herat (tomorrow morning)
((SELECT id FROM buses WHERE plate_number = 'کابل-۱۲۳۴'), (SELECT id FROM transport_companies WHERE company_name = 'افغان ګو اکسپرس'), 'کابل', 'هرات', NOW() + INTERVAL '1 day 08:00', NOW() + INTERVAL '1 day 16:00', 800, 1200, 40, 'scheduled'),
-- Kabul → Herat (tomorrow evening)
((SELECT id FROM buses WHERE plate_number = 'هرات-۲۲۲۲'), (SELECT id FROM transport_companies WHERE company_name = 'خط کابل-هرات'), 'کابل', 'هرات', NOW() + INTERVAL '1 day 18:00', NOW() + INTERVAL '2 day 02:00', 750, 1100, 40, 'scheduled'),
-- Kabul → Mazar (tomorrow)
((SELECT id FROM buses WHERE plate_number = 'مزار-۱۱۱۱'), (SELECT id FROM transport_companies WHERE company_name = 'ستاره شمال'), 'کابل', 'مزارشریف', NOW() + INTERVAL '1 day 06:00', NOW() + INTERVAL '1 day 12:00', 500, 800, 40, 'scheduled'),
-- Kabul → Mazar (VIP)
((SELECT id FROM buses WHERE plate_number = 'مزار-۲۲۲۲'), (SELECT id FROM transport_companies WHERE company_name = 'ستاره شمال'), 'کابل', 'مزارشریف', NOW() + INTERVAL '1 day 10:00', NOW() + INTERVAL '1 day 15:00', 600, 1000, 40, 'scheduled'),
-- Kabul → Kandahar
((SELECT id FROM buses WHERE plate_number = 'کندهار-۱۱۱۱'), (SELECT id FROM transport_companies WHERE company_name = 'وی آی پی اکسپرس'), 'کابل', 'کندهار', NOW() + INTERVAL '1 day 05:00', NOW() + INTERVAL '1 day 14:00', 700, 1100, 40, 'scheduled'),
-- Kabul → Jalalabad
((SELECT id FROM buses WHERE plate_number = 'کابل-۵۶۷۸'), (SELECT id FROM transport_companies WHERE company_name = 'افغان ګو اکسپرس'), 'کابل', 'جلال‌آباد', NOW() + INTERVAL '1 day 07:00', NOW() + INTERVAL '1 day 10:00', 300, 500, 40, 'scheduled'),
-- Kabul → Kunduz
((SELECT id FROM buses WHERE plate_number = 'کابل-۹۹۹۹'), (SELECT id FROM transport_companies WHERE company_name = 'وی آی پی اکسپرس'), 'کابل', 'کندز', NOW() + INTERVAL '1 day 09:00', NOW() + INTERVAL '1 day 15:00', 550, 900, 40, 'scheduled'),
-- Herat → Mazar
((SELECT id FROM buses WHERE plate_number = 'هرات-۱۱۱۱'), (SELECT id FROM transport_companies WHERE company_name = 'خط کابل-هرات'), 'هرات', 'مزارشریف', NOW() + INTERVAL '1 day 06:00', NOW() + INTERVAL '1 day 16:00', 900, 1400, 40, 'scheduled'),
-- Mazar → Kabul (return)
((SELECT id FROM buses WHERE plate_number = 'مزار-۱۱۱۱'), (SELECT id FROM transport_companies WHERE company_name = 'ستاره شمال'), 'مزارشریف', 'کابل', NOW() + INTERVAL '2 day 06:00', NOW() + INTERVAL '2 day 12:00', 500, 800, 40, 'scheduled'),
-- Kandahar → Kabul (return)
((SELECT id FROM buses WHERE plate_number = 'کندهار-۱۱۱۱'), (SELECT id FROM transport_companies WHERE company_name = 'وی آی پی اکسپرس'), 'کندهار', 'کابل', NOW() + INTERVAL '2 day 06:00', NOW() + INTERVAL '2 day 15:00', 700, 1100, 40, 'scheduled');
