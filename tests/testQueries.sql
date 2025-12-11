SELECT DISTINCT m.memID, m.fName, m.lName, w.projID
FROM MEMBER m
JOIN WORK_ON w ON m.memID = w.memID
JOIN FUNDED_BY f ON w.projID = f.projID
WHERE f.grantID = ?
ORDER BY w.projID, m.lName, m.fName

SELECT m1.fName, m1.lName, m2.fName, m2.lName
FROM WORK_ON w1
JOIN MEMBER m1 ON w1.memID = m1.memID
JOIN MEMBER m2 ON m1.mentorID = m2.memID
WHERE w1.projID = ?

SELECT M.memID, M.fName, M.lName, W.projID
FROM USES U
JOIN MEMBER M ON M.memID = U.memID
LEFT JOIN WORK_ON W ON W.memID = M.memID
WHERE U.equipID = ?
AND U.startDate <= CURRENT_DATE
AND (U.endDate IS NULL OR U.endDate >= CURRENT_DATE);

SELECT M.fName, M.lName, Pub.pubCount
FROM MEMBER M
JOIN (
SELECT memID, COUNT(pubID) AS pubCount
FROM AUTHORED_BY
GROUP BY memID
) AS Pub ON M.memID = Pub.memID
ORDER BY Pub.pubCount DESC
LIMIT ?;

SELECT major, AVG(pubCount) AS avgPublications
FROM (
    SELECT S.major, COUNT(A.pubID) AS pubCount
    FROM STUDENT S
    LEFT JOIN AUTHORED_BY A ON A.memID = S.memID
    GROUP BY S.studentNo, S.major
    ) AS StudentCounts
GROUP BY major;

SELECT COUNT(DISTINCT p.projID)
FROM PROJECT p
JOIN FUNDED_BY f ON p.projID = f.projID
WHERE p.statusProj = 'active'
AND (p.endDate IS NULL OR p.endDate >= ?)
AND p.startDate <= ?;

SELECT m.memID, m.fName, m.lName, COUNT(a.pubID) AS pub_count
FROM MEMBER m
JOIN WORK_ON w ON m.memID = w.memID
JOIN FUNDED_BY f ON w.projID = f.projID
LEFT JOIN AUTHORED_BY a ON m.memID = a.memID
WHERE f.grantID = ?
GROUP BY m.memID
ORDER BY pub_count DESC
LIMIT 3