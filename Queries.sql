# Esports Earnings Analysis

CREATE SCHEMA IF NOT EXISTS esports;

# Importing data utilizing MySQL built in Table Import Wizard

USE esports;

# Data exploration

SELECT * FROM earningsbymonth;
SELECT * FROM totalearnings;

SELECT column_name, DATA_TYPE FROM information_schema.columns WHERE table_schema = 'esports' AND table_name = 'earningsbymonth';
SELECT column_name, DATA_TYPE FROM information_schema.columns WHERE table_schema = 'esports' AND table_name = 'totalearnings';

# First, we're going to start by looking at the games in each genre, total earnings in each genre, the number of players, and the number of tournaments
# However, a game with less than 15 or so tournaments probably does not have enough base to meaningfully add to player earnings, though they would still
# contribute a significant amount to the player count. As such, games with less than 15 tournaments are removed from the genre count.
# Furthermore, to filter a bit farther, we would like to look at games with an average of $1000 in earnings per tournament, so we will filter this down 
# to where Total Earnings > $15000 (>= 15 tournaments, $1000/tournament). When we get to EarningsByMonth we will set individual tournament prizepool requirements,
# but for now we will make due.

SELECT Genre, COUNT(Genre) AS 'Games in Genre', ROUND(SUM(TotalEarnings),0) AS 'Total Genre Earnings', ROUND(SUM(OnlineEarnings),0) 'Total Genre Earnings - Online',
	   SUM(TotalPlayers) AS 'Total Players' , SUM(TotalTournaments) AS 'Total Tournaments'
FROM totalearnings
WHERE TotalTournaments >= 15 AND TotalEarnings >= 15000
GROUP BY Genre
ORDER BY SUM(TotalEarnings) DESC;

# As we can see here, Multiplayer Online Battle Arenas, First Person Shooters, and Battle Royales make up a significantly larger portion of total prize pools
# than other genres. Let's continue by taking a closer look at MOBAs. I will keep the 15 tournament/15,000 rule for consistency.

SELECT *
FROM totalearnings
WHERE Genre = 'Multiplayer Online Battle Arena'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
ORDER BY TotalEarnings DESC;

# DotA 2 and League of Legends make up a vast majority of the earnings (partly because they have more tournaments than every other MOBA combined, and partly because 
# they both utilize versions of the crowd funding model

# I disagree with the classification of Minecraft as a MOBA so I am going to reassign it

SELECT DISTINCT Genre 
FROM TotalEarnings
GROUP BY Genre;

# Of these categories, Role-Playing Game is the closest though it's not a great match. Minecraft is just not a MOBA.

SET SQL_SAFE_UPDATES = 0; # ONLY USE THIS COMMAND IF YOU COMPLETELY UNDERSTAND WHAT YOUR QUERY IS DOING.

UPDATE TotalEarnings
SET Genre = 'Role-Playing Game'
WHERE Game = 'Minecraft';

SELECT *
FROM TotalEarnings
WHERE Genre = 'Role-Playing Game';

SELECT *
FROM TotalEarnings
WHERE Game = 'Minecraft';

# Good to go.

# Percentage Calculation for MOBAs. I might consider condensing this into a function for later, but this is heavily reusable as it stands with altered filters.

SELECT Game, Genre, TotalEarnings, TotalPlayers, TotalTournaments,
	ROUND(TotalEarnings * 100 / (SELECT SUM(TotalEarnings) AS TE 
    FROM TotalEarnings 
    WHERE Genre = 'Multiplayer Online Battle Arena'
    AND TotalTournaments >= 15
	AND TotalEarnings >= 15000),2) AS 'Percent of Total'
FROM TotalEarnings
WHERE Genre = 'Multiplayer Online Battle Arena'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY TotalEarnings DESC;

# From this, we can see that Dota 2 makes up 64.01% of MOBA earnings, League makes up 22.9%, Heroes of the Storm (HOTS) is 5.1%, and it goes from there.
# Next, we can look at some other metrics such as earnings per player, earnings/tournament, etc...

# Total Earnings / Player - Segmented by Game - MOBAs

SELECT Game, TotalEarnings, TotalPlayers, ROUND(SUM(TotalEarnings)/SUM(TotalPlayers),2) AS 'Earnings per Player'
FROM TotalEarnings
WHERE Genre = 'Multiplayer Online Battle Arena'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY SUM(TotalEarnings)/SUM(TotalPlayers) DESC;

# So, while League of Legends is 2nd in MOBA earnings, it is actually 5th in earnings per player. This could be due to more Division 2 or 3 tournaments being held.
# This will be an interesting trend to look into later on with the earningsbymonth data set.

# Total Earnings / Tournament - MOBAs

SELECT Game, TotalEarnings, TotalTournaments, ROUND(SUM(TotalEarnings)/SUM(TotalTournaments),2) AS 'Earnings per Tournament'
FROM TotalEarnings
WHERE Genre = 'Multiplayer Online Battle Arena'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY SUM(TotalEarnings)/SUM(TotalTournaments) DESC;

# Arena of Valor has more Earnings per Tournament than Dota 2, which would seem to indicate that its fewer tournaments have lower prizepools than Dota 2
# This makes sense, because a lot of Dota 2's earnings come from their 'The International' (World Championship) series that utilizes crowdfunding for the 
# largest prizepools in esports history

# Total Players / Tournament - MOBAs -- FLAWED METRIC -- "TotalPlayers" counts Unique Players

# SELECT Game, TotalTournaments, TotalPlayers, ROUND(SUM(TotalPlayers)/SUM(TotalTournaments),0) AS 'Players per Tournament'
# FROM TotalEarnings
# WHERE Genre = 'Multiplayer Online Battle Arena'
# AND TotalTournaments >= 15
# AND TotalEarnings >= 15000
# GROUP BY Game
# ORDER BY SUM(TotalPlayers)/SUM(TotalTournaments) DESC;

# Total Earnings / Player - Segmented by Genre

SELECT Genre, SUM(TotalEarnings) AS 'Total Earnings', SUM(TotalPlayers) AS 'Total Players', ROUND(SUM(TotalEarnings)/SUM(TotalPlayers),2) AS 'Earnings per Player'
FROM TotalEarnings
WHERE TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Genre
ORDER BY SUM(TotalEarnings)/SUM(TotalPlayers) DESC;

# MOBAs generate the highest earnings per player; likely because of the high earnings of the Dota 2 and League of Legends World Championships.

# Total Earnings / Tournament - Segmented by Genre

SELECT Genre, ROUND(SUM(TotalEarnings),0) as 'Total Earnings', SUM(TotalTournaments) AS 'Total Tournaments', ROUND(SUM(TotalEarnings)/SUM(TotalTournaments),2) AS 'Earnings per Tournament'
FROM TotalEarnings
WHERE TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Genre
ORDER BY SUM(TotalEarnings)/SUM(TotalTournaments) DESC;

# Battle Royale games have the highest earnings per tournament; likely due to the relatively low amount of Fortnite tournaments with very high prize pools
# However, this will be explored later as I will break down the more profitable genres by game (in addition to prior MOBA analysis).

# Since MOBAs, Third Person Shooters, and Battle Royales have the highest Earnings/Player I am going to quickly run through the analysis I did on MOBAs with 
# TPS and BR games as well

# Total Earnings / Player - Segmented by Game - Battle Royale

SELECT Game, TotalEarnings, TotalPlayers, ROUND(SUM(TotalEarnings)/SUM(TotalPlayers),2) AS 'Earnings per Player'
FROM TotalEarnings
WHERE Genre = 'Battle Royale'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY SUM(TotalEarnings)/SUM(TotalPlayers) DESC;

# This comment generated after data set fixed: Fortnite and PubG are definitely the two highest for earnings/player, so I am glad that this was fixed.
# However, my other insights may need to be examined to see if the reintroduction of games with apostrophies made any major difference.

##############################
# DATA CLEANING FIX START

# This query is strange because PLAYERUNKNOWN'S BATTLEGROUNDS isn't appearing when I know full well it meets these criteria

SELECT *
FROM TotalEarnings
WHERE Genre = 'Battle Royale';

# It is still missing

# SELECT *
# FROM TotalEarnings;

# Re-importing the data to see if there was anything that changed. It appears that the apostrophe in the name stopped the import, something that I missed in my cleaning.

# SELECT * 
# FROM generalesportdata; TEMPORARY TABLE

# Re-importing the data with the few games that were missing due to this, going to name the table TotalEarnings as it was previously. Query should function properly.
# The more you know, I suppose, glad I caught this before I went deeper.

# DATA CLEANING FIX END
##############################

# Total Earnings / Tournament - Battle Royale

SELECT Game, TotalEarnings, TotalTournaments, ROUND(SUM(TotalEarnings)/SUM(TotalTournaments),2) AS 'Earnings per Tournament'
FROM TotalEarnings
WHERE Genre = 'Battle Royale'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY SUM(TotalEarnings)/SUM(TotalTournaments) DESC;

# PUBG and PUBG Mobile had 2 of the highest earnings per tournament, re-integrating the proper data is highly beneficial. I will have to take a closer look at import restrictions in the future.

# Total Earnings / Player - Segmented by Game - Third Person Shooter

SELECT Game, TotalEarnings, TotalPlayers, ROUND(SUM(TotalEarnings)/SUM(TotalPlayers),2) AS 'Earnings per Player'
FROM TotalEarnings
WHERE Genre = 'Third-Person Shooter'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY SUM(TotalEarnings)/SUM(TotalPlayers) DESC;

# The profitable TPS games are completely made up of Gear of War games. If we were to do statistical analysis, we might be tempted to overlook this genre because 
# there are so few TPS games; meaning that Gears of War might be the reason for high earnings/player, rather than the TPS genre as a whole. 

# Total Earnings / Tournament - Third Person Shooter

SELECT Game, TotalEarnings, TotalTournaments, ROUND(SUM(TotalEarnings)/SUM(TotalTournaments),2) AS 'Earnings per Tournament'
FROM TotalEarnings
WHERE Genre = 'Third-Person Shooter'
AND TotalTournaments >= 15
AND TotalEarnings >= 15000
GROUP BY Game
ORDER BY SUM(TotalEarnings)/SUM(TotalTournaments) DESC;

# Really not much to analyze with so few games; though GOW4 and GOW5 are far more profitable than the original. It's interesting that GOW2 and GOW3 didn't have larger tournament scenes.

SELECT *
FROM TotalEarnings
WHERE Genre = 'Third-Person Shooter';

# As noted before, Gears of War: Ultimate Edition, Gears of War 2, Gears of War 3, and The Division 2 all failed the Tournament count and earnings metrics, though tournaments existed.
