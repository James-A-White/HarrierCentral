-- =====================================================================
-- RUN-ONCE — TEST IMPORT of Chichester H3 runs from www.chihhh.org.uk
-- (James, 2026-10-03: "import a few recent Chichester runs as a test...
-- maybe runs for September of this year").
-- Reproduces hcportal_addEditEvent's INSERT path exactly (no portal token
-- to call it with): the same columns and defaults, then the same
-- HC6.nonApi_updateRunNumbers + nonApi_updateRunCountsForEventUsers, in one
-- transaction. EventSource marks the rows. Skips a run whose number the
-- kennel already has, so it is safe to re-run. Start = the run's LOCAL wall
-- clock with +00:00, as the kennel's own run #1095 is stored (GMT is derived
-- from the kennel's timezone). Archive after running.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @kennelId UNIQUEIDENTIFIER, @countryId UNIQUEIDENTIFIER, @eventId UNIQUEIDENTIFIER;
SELECT @kennelId = id, @countryId = CountryId FROM HC.Kennel
WHERE PublicKennelId = '5540500b-f9ce-454c-a7f0-96803a1039c9' AND KennelName LIKE 'Chichester%';
IF @kennelId IS NULL THROW 50001, 'Chichester kennel not found', 1;
BEGIN TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM HC.Event WHERE KennelId = @kennelId AND deleted = 0
               AND (AbsoluteEventNumber = 1093 OR EventNumber = 1093))
BEGIN
    SET @eventId = NEWID();
    INSERT HC.Event WITH (ROWLOCK)
    (id, PublicEventId, KennelId, EventStartDatetime, EventEndDatetime,
     IsCountedRun, IsVisible, IsPromotedEvent, CanEditRunAttendence,
     EventGeographicScope, InboundIntegrationId, EventName, EventDescription,
     LocationCity, LocationStreet, LocationPostCode, LocationCountry,
     LocationRegion, LocationSubRegion, LocationOneLineDesc, EventImage,
     Latitude, Longitude, EventGeolocation,
     EventPriceForMembers, EventPriceForNonMembers, EventPriceForExtras,
     ExtrasDescription, ExtrasRsvpRequired, IntegrationEnabled, AbsoluteEventNumber,
     Hares, Tags1, Tags2, Tags3,
     UseFbImage, UseFbLatLon, UseFbLocation, UseFbRunDetails,
     MaximumParticipantsAllowed, MinimumParticipantsRequired,
     EvtDisseminationAudience, EvtDisseminateAllowWebLinks,
     EvtDisseminateHashRunsDotOrg, DisseminateOnGlobalGoogleCalendar,
     deleted, updatedAt, EventSource, CountryId, RegionId, CityId, TimezoneId)
    VALUES
    (@eventId, NEWID(), @kennelId, '2026-09-06T11:00:00+00:00', NULL,
     1, 1, 0, NULL,
     1, 0, N'Run 1093 - Sheet, Half Moon (joint run with Haslemere H4)', N'In true British tradition, lets talk about the weather, it is of interest because the running is
so much more pleasant now that there has been some rain. It is cooler and like Lazarus
the grass has risen from the hard brown death and burst into an almost springtime soft green,
kind on the eyes, kind on the feet. 
No rain for this run, a dry warm Goldilocks day that attracted around sixty Hashers from several
"local" kennels, disorganised by Haslemere HHH and Hares Chilly Willy and Nutcracker. The rather
small Chi contingent had the opportunity to make or renew acquaintance with the hosts, Portsmouth,
North Hants, Deepcut and Hursley Hashers. 
We circled up in the Half Moon (Sheet) car park for the "Chalk Talk", which as you can image was
a little chaotic. Nutctacker tried to impart her attempt at a lingua franca, which seemed to have
two sorts of regroup markings, lines, lines with arrows of different directions, fish hooks "Booo!"
and "three and you are on", "Hooooray!". When she had run out of patience with the cross examinations
she made a bit more than just an elbow of directional encouragement and implored us to
gird up our loins and skedaddle, which of course we did with alacrity, heading South on London Road. 
Straight off the bat, there was a very inviting field entrance just opposite, with a five bar gate and smaller
pedestrian gate to it''s right, just the sort of setup we always see at the start of a public footpath, you know
what I mean. Despite both gates being locked up with two big padlocked blue plastic covered chains many
of the pack seemed convinced that the trail would go through, leading to a pile up of pack in the deep
gateway area, those running in and those turning round to come out going nose to nose for a time.
Meanwhile those who had been slower off the blocks had found a good trail down Pulens Lane and then
East over the Rother at the Old Mill, where there was plenty of water, plenty of murky looking water. 
On the East bank its shady woods, narrow bramble edged paths over many a gnarly root, with a few false
trails continuing East until we break out into daylight on Sheet Common. The government would say "wait
for the outcome of the enquiry" to find out what happened next. Several witnesses have been called, the
outcome is uncertain. From Dancer and Bambi''s POV we found good dust almost to Sheet Common Way
where we heard "on on" from the path South, we headed South but no sign of dust but calling ahead and
it''s down hill so what''s not to like. We reached the tree line above the Rother, and saw hashers to our right,
we followed. Now in retrospect, looking at a GPS track, I see those ahead of us must have stumbled on
a false trail from an earlier check and not realised until we arrived back at where we had first arrived
on the common. Oh dear! nothing for it but to run back up the hill again to where it all went wrong to find
a helpful Hare (Is that an oxymoron?) who ushered us North, off the common, down to the main road,
along Mill Lane where the pack had ground to a halt at a check on the entrance to Millenium Field. 
Our very own Dancer found the true trail here, which lay all around the outside edge, heading North to
cross the railway line. Most of the pack led by the likes of Yellow Peril, Yorkie, K9, etc. were involved in
a mass short cut exercise, there is I suppose safety in numbers, the hawk fails to catch the starling, unable
to focus in the murmuration, although Bambi has camera evidence me lud. 
Over the tracks, and up the lane past Burntash Farm, under the A3, not really noticing these highways
as we move at pace on lovely green soft flat grassland and firm lanes. Then a little "there and back" loop
towards the fish farm where guess what ? yes! a fish hook before heading North past the tradesman''s
entrance to Elmswood House before turning West and taking the open green …

Full run report: https://www.chihhh.org.uk/run1093.php',
     N'Sheet', NULL, NULL, N'United Kingdom',
     NULL, NULL, N'Sheet Half Moon', NULL,
     51.01401, -0.917762, geography::Point(51.01401, -0.917762, 4326),
     NULL, NULL, NULL,
     NULL, 0, 0, 1093,
     N'Nutcracker & Chilly Willy', 0, 0, 0,
     0, 0, 0, 0,
     NULL, NULL,
     NULL, NULL, NULL, NULL,
     0, GETDATE(), N'Import chihhh.org.uk', @countryId, NULL, NULL, NULL);
    EXEC HC6.nonApi_updateRunNumbers @eventId = @eventId;
    EXEC HC6.nonApi_updateRunCountsForEventUsers @eventId = @eventId;
    PRINT 'Imported run 1093';
END
ELSE PRINT 'Run 1093 already exists - skipped';

IF NOT EXISTS (SELECT 1 FROM HC.Event WHERE KennelId = @kennelId AND deleted = 0
               AND (AbsoluteEventNumber = 1094 OR EventNumber = 1094))
BEGIN
    SET @eventId = NEWID();
    INSERT HC.Event WITH (ROWLOCK)
    (id, PublicEventId, KennelId, EventStartDatetime, EventEndDatetime,
     IsCountedRun, IsVisible, IsPromotedEvent, CanEditRunAttendence,
     EventGeographicScope, InboundIntegrationId, EventName, EventDescription,
     LocationCity, LocationStreet, LocationPostCode, LocationCountry,
     LocationRegion, LocationSubRegion, LocationOneLineDesc, EventImage,
     Latitude, Longitude, EventGeolocation,
     EventPriceForMembers, EventPriceForNonMembers, EventPriceForExtras,
     ExtrasDescription, ExtrasRsvpRequired, IntegrationEnabled, AbsoluteEventNumber,
     Hares, Tags1, Tags2, Tags3,
     UseFbImage, UseFbLatLon, UseFbLocation, UseFbRunDetails,
     MaximumParticipantsAllowed, MinimumParticipantsRequired,
     EvtDisseminationAudience, EvtDisseminateAllowWebLinks,
     EvtDisseminateHashRunsDotOrg, DisseminateOnGlobalGoogleCalendar,
     deleted, updatedAt, EventSource, CountryId, RegionId, CityId, TimezoneId)
    VALUES
    (@eventId, NEWID(), @kennelId, '2026-09-20T11:00:00+00:00', NULL,
     1, 1, 0, NULL,
     1, 0, N'Run 1094 - Westbourne, Ems Valley Memorial Arboretum', N'I''s been on me hols I has, and now, pushed for time all you gets is the bullets. 

 It was a lovely sunny end of summer day. 
 There was just eleven of us bipeds, and two quadrupeds. 
 Cock Burns suffering after an armful of MMR juice, not as bad as catching MMR though. 
 Tried to decide on a number for the fish hook, then realised only needed for Dancer. 
 Nice quiet car park at the arboretum, how come we have not used this before ? answers
on the back of a ten pound note please. 
 We set off through Hampshire Farm Meadow, must be one of the highest density dog
walker areas on the planet, little sign of any crap hazards or little blue parcels however. 
 Arrive at the exit on Long Copse Lane and go East, Dancer disappears ahead and
reaches his fish hook with a long way back to the back, tee hee 
 North past new houses, another nibble out of the ancient Forest of Bere, into Hollybank
Woods, a great place for not knowing where you are. 
 We are doing an anticlockwise circuit a respectful distance from the outer boundaries
with the aim of a ren dez vooz with the walkers at the carved seat on The Sussex Border Path. 
 We loose Kinky at approx SU7464708100, he disappears, he has been abducted by aliens. 
 We arrive at the meet seat, crack the port, and over a sip or two decide to continue in the hope
he will find us using all the little arrows that Old Faithful has meticulously laid. 
 Kinky is still missing by the time we reach the woodland exit, a small search party returns to
look for him, the rest to continue back to the chariots, not too far away. 
 Why don''t we try calling Kinky, good idea, voicemail on direct number, ring forever on a WhatsApp
call. Little did we know that his phone is safely locked in the back of Bambi''s chariot. 
 Party starts from last known sighting of Kinky, place where the big bright blue column of light
must have whisked him up into the alien craft where no doubt he had been interrogated to find out
the secrets that only hashers know, you know, those secrets that we have pledged to guard with our
lives, you know, THOSE secrets. 
 Oh Yes! I should mention that all the time we are calling "Kinky! Kinky!" or "Ray! Ray! to
no avail. 
 Phew! we receive the news that he has rocked in to the car park. BIG relief, like when you think
you have lost your wallet and then you find it in the footwell behind your seat. Obviously a person
is more important than mere money, even Kinky. 
 Finally we are all back, and discovering that Pru has set out a small feast, fewer
people means more for us, thanks Pru, there was more than the usual hunger and thirst around. 
 Hash Shit awarded to the lost sheep, amongst rejoicing his return to the fold with ale and song. 
 A couple of picnic rugs in the warm sun, proved too inviting for Bambi, he would still have been
there napping if someone had not pulled his leg and woken him up to find everything was packed
away and ready to go. 
 So he got up and left. 

 On-On! Sir Bambi

(Imported from https://www.chihhh.org.uk/run1094.php)',
     N'Westbourne', NULL, NULL, N'United Kingdom',
     NULL, NULL, N'Westbourne Ems Valley Memorial Arboretum', NULL,
     50.861524, -0.932663, geography::Point(50.861524, -0.932663, 4326),
     NULL, NULL, NULL,
     NULL, 0, 0, 1094,
     N'Old Faithful & Bambi', 0, 0, 0,
     0, 0, 0, 0,
     NULL, NULL,
     NULL, NULL, NULL, NULL,
     0, GETDATE(), N'Import chihhh.org.uk', @countryId, NULL, NULL, NULL);
    EXEC HC6.nonApi_updateRunNumbers @eventId = @eventId;
    EXEC HC6.nonApi_updateRunCountsForEventUsers @eventId = @eventId;
    PRINT 'Imported run 1094';
END
ELSE PRINT 'Run 1094 already exists - skipped';

COMMIT TRANSACTION;

SELECT e.EventNumber, e.AbsoluteEventNumber, CONVERT(varchar(16), e.EventStartLocal, 120) AS startLocal,
       CONVERT(varchar(16), e.EventStartDatetimeGmt, 120) AS startGmt, e.EventName, e.Hares,
       e.LocationOneLineDesc, LEN(e.EventDescription) AS descLen, e.EventSource
FROM HC.Event e WHERE e.KennelId = @kennelId AND e.deleted = 0 ORDER BY e.EventStartDatetimeGmt;
