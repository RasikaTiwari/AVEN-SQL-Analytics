
    --AVEN — BUSINESS ANALYSIS

   --Database: AVEN
   --Platform: Microsoft SQL Server / SSMS

   --PURPOSE:
   --Answer 20 business questions using SQL to analyze sales, products,
   --inventory, customers, promotions, returns, and supplier performance. 



/*
   Q1. What is AVEN's total sales revenue?
   ---------------------------------------------------------------------*/

SELECT
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS TotalSalesRevenue
FROM SaleItem si
JOIN Sale s
    ON si.SaleID = s.SaleID
WHERE s.SaleStatus = 'Completed';


/* ---------------------------------------------------------------------
   Q2. What are AVEN's top revenue-generating products?
   --------------------------------------------------------------------- */

SELECT
    p.ProductID,
    p.ProductName,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS Revenue
FROM SaleItem si
JOIN Sale s
    ON si.SaleID = s.SaleID
JOIN ProductVariant pv
    ON si.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
WHERE s.SaleStatus = 'Completed'
GROUP BY
    p.ProductID,
    p.ProductName
ORDER BY Revenue DESC;


/* ---------------------------------------------------------------------
   Q3. Which product categories generate the most revenue?
   --------------------------------------------------------------------- */

SELECT
    p.Category,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS Revenue
FROM SaleItem si
JOIN Sale s
    ON si.SaleID = s.SaleID
JOIN ProductVariant pv
    ON si.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
WHERE s.SaleStatus = 'Completed'
GROUP BY p.Category
ORDER BY Revenue DESC;


/* ---------------------------------------------------------------------
   Q4. Which stores generate the most revenue?
   --------------------------------------------------------------------- */

SELECT
    l.LocationName,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS Revenue
FROM SaleItem si
JOIN Sale s
    ON si.SaleID = s.SaleID
JOIN Store st
    ON s.StoreLocationID = st.LocationID
JOIN Location l
    ON st.LocationID = l.LocationID
WHERE s.SaleStatus = 'Completed'
GROUP BY
    l.LocationID,
    l.LocationName
ORDER BY Revenue DESC;


/* ---------------------------------------------------------------------
   Q5. Which products are bestsellers, and which are underperforming?

   Rank products by units sold.
   --------------------------------------------------------------------- */

SELECT
    p.ProductID,
    p.ProductName,
    SUM(si.Quantity) AS UnitsSold,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS Revenue
FROM SaleItem si
JOIN Sale s
    ON si.SaleID = s.SaleID
JOIN ProductVariant pv
    ON si.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
WHERE s.SaleStatus = 'Completed'
GROUP BY
    p.ProductID,
    p.ProductName
ORDER BY UnitsSold DESC;


/* ---------------------------------------------------------------------
   Q6. Which products have high ratings but low sales? */

WITH ProductRatings AS
(
    SELECT
        pv.ProductID,
        AVG(CAST(r.Rating AS DECIMAL(10,2))) AS AverageRating,
        COUNT(r.ReviewID) AS ReviewCount
    FROM ProductVariant pv
    JOIN Review r
        ON pv.VariantID = r.VariantID
    GROUP BY pv.ProductID
),
ProductSales AS
(
    SELECT
        pv.ProductID,
        SUM(si.Quantity) AS UnitsSold
    FROM ProductVariant pv
    JOIN SaleItem si
        ON pv.VariantID = si.VariantID
    JOIN Sale s
        ON si.SaleID = s.SaleID
    WHERE s.SaleStatus = 'Completed'
    GROUP BY pv.ProductID
)
SELECT
    p.ProductID,
    p.ProductName,
    pr.AverageRating,
    pr.ReviewCount,
    ISNULL(ps.UnitsSold, 0) AS UnitsSold
FROM Product p
JOIN ProductRatings pr
    ON p.ProductID = pr.ProductID
LEFT JOIN ProductSales ps
    ON p.ProductID = ps.ProductID
WHERE pr.AverageRating >= 4
  AND ISNULL(ps.UnitsSold, 0) < 20
ORDER BY
    pr.AverageRating DESC,
    UnitsSold ASC;


/* ---------------------------------------------------------------------
   Q7. Which products generate high revenue but also have high
       return rates?

   Return rate = units returned / units sold * 100.
   --------------------------------------------------------------------- */

WITH SalesData AS
(
    SELECT
        p.ProductID,
        p.ProductName,
        SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
            AS Revenue,
        SUM(si.Quantity) AS UnitsSold
    FROM SaleItem si
    JOIN Sale s
        ON si.SaleID = s.SaleID
    JOIN ProductVariant pv
        ON si.VariantID = pv.VariantID
    JOIN Product p
        ON pv.ProductID = p.ProductID
    WHERE s.SaleStatus = 'Completed'
    GROUP BY
        p.ProductID,
        p.ProductName
),
ReturnData AS
(
    SELECT
        pv.ProductID,
        SUM(ri.QuantityReturned) AS UnitsReturned
    FROM ReturnItem ri
    JOIN [Return] r
        ON ri.ReturnID = r.ReturnID
    JOIN SaleItem si
        ON ri.SaleItemID = si.SaleItemID
    JOIN ProductVariant pv
        ON si.VariantID = pv.VariantID
    GROUP BY pv.ProductID
)
SELECT
    sd.ProductID,
    sd.ProductName,
    sd.Revenue,
    sd.UnitsSold,
    ISNULL(rd.UnitsReturned, 0) AS UnitsReturned,
    ROUND(
        100.0 * ISNULL(rd.UnitsReturned, 0)
        / NULLIF(sd.UnitsSold, 0),
        2
    ) AS ReturnRate
FROM SalesData sd
LEFT JOIN ReturnData rd
    ON sd.ProductID = rd.ProductID
ORDER BY
    ReturnRate DESC,
    sd.Revenue DESC;


/* =====================================================================
   SECTION 2 — INVENTORY & REPLENISHMENT
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q8. Which products are at risk of stockout?

   Stockout risk: available quantity is at or below reorder level.
   --------------------------------------------------------------------- */

SELECT
    p.ProductID,
    p.ProductName,
    pv.VariantID,
    pv.Color,
    pv.Size,
    l.LocationName,
    i.QuantityAvailable,
    i.ReorderLevel
FROM Inventory i
JOIN ProductVariant pv
    ON i.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
JOIN Location l
    ON i.LocationID = l.LocationID
WHERE i.QuantityAvailable <= i.ReorderLevel
ORDER BY
    i.QuantityAvailable ASC;


/* ---------------------------------------------------------------------
   Q9. Which products have excess inventory?

   Here, excess inventory is defined as available stock greater than
   three times the reorder level. This is an analytical threshold,
   not an existing AVEN business rule.
   --------------------------------------------------------------------- */

SELECT
    p.ProductID,
    p.ProductName,
    pv.VariantID,
    pv.Color,
    pv.Size,
    l.LocationName,
    i.QuantityAvailable,
    i.ReorderLevel
FROM Inventory i
JOIN ProductVariant pv
    ON i.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
JOIN Location l
    ON i.LocationID = l.LocationID
WHERE i.QuantityAvailable > 3 * i.ReorderLevel
ORDER BY
    i.QuantityAvailable DESC;


/* ---------------------------------------------------------------------
   Q10. Which locations have inventory gaps?

   Shows product variants at each location where stock is at or below
   the reorder level.
   --------------------------------------------------------------------- */

SELECT
    l.LocationName,
    p.ProductName,
    pv.VariantID,
    pv.Color,
    pv.Size,
    i.QuantityAvailable,
    i.ReorderLevel,
    i.ReorderLevel - i.QuantityAvailable AS StockGap
FROM Inventory i
JOIN Location l
    ON i.LocationID = l.LocationID
JOIN ProductVariant pv
    ON i.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
WHERE i.QuantityAvailable <= i.ReorderLevel
ORDER BY
    l.LocationName,
    StockGap DESC;


/* ---------------------------------------------------------------------
   Q11. Which products should be prioritized for replenishment?

   Replenishment quantity = reorder level - available stock.
   --------------------------------------------------------------------- */

SELECT
    p.ProductID,
    p.ProductName,
    pv.VariantID,
    pv.Color,
    pv.Size,
    l.LocationName,
    i.QuantityAvailable,
    i.ReorderLevel,
    CASE
        WHEN i.QuantityAvailable = 0 THEN 'Out of Stock'
        WHEN i.QuantityAvailable < i.ReorderLevel THEN 'High Priority'
        ELSE 'Monitor'
    END AS ReplenishmentPriority,
    CASE
        WHEN i.ReorderLevel > i.QuantityAvailable
            THEN i.ReorderLevel - i.QuantityAvailable
        ELSE 0
    END AS SuggestedReorderQuantity
FROM Inventory i
JOIN ProductVariant pv
    ON i.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
JOIN Location l
    ON i.LocationID = l.LocationID
WHERE i.QuantityAvailable <= i.ReorderLevel
ORDER BY
    SuggestedReorderQuantity DESC;


/* =====================================================================
   SECTION 3 — CUSTOMER ANALYSIS
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q12. What is AVEN's major customer age group?

   Age groups are calculated using the current date.
   --------------------------------------------------------------------- */

WITH CustomerAges AS
(
    SELECT
        CustomerID,
        DateOfBirth,
        DATEDIFF(YEAR, DateOfBirth, GETDATE())
        - CASE
            WHEN DATEADD(
                YEAR,
                DATEDIFF(YEAR, DateOfBirth, GETDATE()),
                DateOfBirth
            ) > GETDATE()
            THEN 1
            ELSE 0
          END AS Age
    FROM Customer
    WHERE DateOfBirth IS NOT NULL
)
SELECT
    CASE
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Above 60'
    END AS AgeGroup,
    COUNT(*) AS CustomerCount
FROM CustomerAges
GROUP BY
    CASE
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Above 60'
    END
ORDER BY CustomerCount DESC;


/* ---------------------------------------------------------------------
   Q13. Which customer segments are most valuable to AVEN?

   Compare revenue and number of orders by customer segment.
   --------------------------------------------------------------------- */

SELECT
    c.CustomerSegment,
    COUNT(DISTINCT s.SaleID) AS TotalOrders,
    COUNT(DISTINCT c.CustomerID) AS Customers,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS Revenue
FROM Customer c
JOIN Sale s
    ON c.CustomerID = s.CustomerID
JOIN SaleItem si
    ON s.SaleID = si.SaleID
WHERE s.SaleStatus = 'Completed'
GROUP BY c.CustomerSegment
ORDER BY Revenue DESC;


/* ---------------------------------------------------------------------
   Q14. During which months did customer registrations peak, and
        how do those months compare with promotion periods?

   This compares timing only. It does not prove that promotions
   caused an increase in registrations.
   --------------------------------------------------------------------- */

WITH MonthlyRegistrations AS
(
    SELECT
        YEAR(RegistrationDate) AS RegistrationYear,
        MONTH(RegistrationDate) AS RegistrationMonth,
        COUNT(*) AS NewCustomers
    FROM Customer
    GROUP BY
        YEAR(RegistrationDate),
        MONTH(RegistrationDate)
)
SELECT
    mr.RegistrationYear,
    mr.RegistrationMonth,
    mr.NewCustomers,
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM Promotion pr
            WHERE YEAR(pr.StartDate) = mr.RegistrationYear
              AND MONTH(pr.StartDate) = mr.RegistrationMonth
        )
        THEN 'Promotion Started'
        ELSE 'No Promotion Started'
    END AS PromotionTiming
FROM MonthlyRegistrations mr
ORDER BY
    mr.NewCustomers DESC;


/* =====================================================================
   SECTION 4 — PROMOTION & DISCOUNT ANALYSIS
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q15. How effective are AVEN's promotions?

   Compare revenue and units sold for promotion-linked variants
   during the promotion period.

   Note: The schema does not directly link a sale to a PromotionID.
   This query uses promotion dates and linked variants as a proxy.
   --------------------------------------------------------------------- */

SELECT
    pr.PromotionID,
    pr.PromotionName,
    pr.StartDate,
    pr.EndDate,
    SUM(si.Quantity) AS UnitsSoldDuringPromotion,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS RevenueDuringPromotion
FROM Promotion pr
JOIN PromotionProduct pp
    ON pr.PromotionID = pp.PromotionID
JOIN SaleItem si
    ON pp.VariantID = si.VariantID
JOIN Sale s
    ON si.SaleID = s.SaleID
WHERE s.SaleStatus = 'Completed'
  AND s.SaleDateTime >= pr.StartDate
  AND s.SaleDateTime < DATEADD(DAY, 1, pr.EndDate)
GROUP BY
    pr.PromotionID,
    pr.PromotionName,
    pr.StartDate,
    pr.EndDate
ORDER BY RevenueDuringPromotion DESC;


/* ---------------------------------------------------------------------
   Q16. How does discount level relate to sales?

   Group sale items into discount bands and compare units sold
   and revenue. This is descriptive, not proof of causation.
   --------------------------------------------------------------------- */

SELECT
    CASE
        WHEN ISNULL(si.DiscountAmount, 0) = 0
            THEN 'No Discount'
        WHEN si.DiscountAmount / NULLIF(
            si.Quantity * si.UnitPrice, 0
        ) <= 0.10
            THEN 'Up to 10%'
        WHEN si.DiscountAmount / NULLIF(
            si.Quantity * si.UnitPrice, 0
        ) <= 0.25
            THEN '10%-25%'
        ELSE 'Above 25%'
    END AS DiscountBand,
    SUM(si.Quantity) AS UnitsSold,
    SUM(si.Quantity * si.UnitPrice - ISNULL(si.DiscountAmount, 0))
        AS Revenue,
    SUM(ISNULL(si.DiscountAmount, 0)) AS TotalDiscount
FROM SaleItem si
JOIN Sale s
    ON si.SaleID = s.SaleID
WHERE s.SaleStatus = 'Completed'
GROUP BY
    CASE
        WHEN ISNULL(si.DiscountAmount, 0) = 0
            THEN 'No Discount'
        WHEN si.DiscountAmount / NULLIF(
            si.Quantity * si.UnitPrice, 0
        ) <= 0.10
            THEN 'Up to 10%'
        WHEN si.DiscountAmount / NULLIF(
            si.Quantity * si.UnitPrice, 0
        ) <= 0.25
            THEN '10%-25%'
        ELSE 'Above 25%'
    END
ORDER BY UnitsSold DESC;


/* =====================================================================
   SECTION 5 — RETURNS & CUSTOMER EXPERIENCE
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q17. Which products have the highest number of returned units?
   --------------------------------------------------------------------- */

SELECT
    p.ProductID,
    p.ProductName,
    SUM(ri.QuantityReturned) AS UnitsReturned,
    SUM(r.RefundAmount) AS TotalRefundAmount
FROM [Return] r
JOIN ReturnItem ri
    ON r.ReturnID = ri.ReturnID
JOIN SaleItem si
    ON ri.SaleItemID = si.SaleItemID
JOIN ProductVariant pv
    ON si.VariantID = pv.VariantID
JOIN Product p
    ON pv.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.ProductName
ORDER BY UnitsReturned DESC;


/* ---------------------------------------------------------------------
   Q18. What are the main return reasons and their financial impact?
   --------------------------------------------------------------------- */

SELECT
    r.ReturnReason,
    COUNT(DISTINCT r.ReturnID) AS NumberOfReturns,
    SUM(ri.QuantityReturned) AS UnitsReturned,
    SUM(r.RefundAmount) AS TotalRefundAmount
FROM [Return] r
JOIN ReturnItem ri
    ON r.ReturnID = ri.ReturnID
GROUP BY r.ReturnReason
ORDER BY TotalRefundAmount DESC;


/* =====================================================================
   SECTION 6 — SUPPLIER PERFORMANCE
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q19. Which suppliers have the best and worst delivery performance?

   On-time delivery means ActualDeliveryDate is on or before
   ExpectedDeliveryDate.
   --------------------------------------------------------------------- */

SELECT
    sup.SupplierID,
    sup.SupplierName,
    COUNT(po.PurchaseOrderID) AS DeliveredOrders,
    SUM(
        CASE
            WHEN po.ActualDeliveryDate <= po.ExpectedDeliveryDate
                THEN 1
            ELSE 0
        END
    ) AS OnTimeOrders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN po.ActualDeliveryDate <= po.ExpectedDeliveryDate
                    THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(po.PurchaseOrderID), 0),
        2
    ) AS OnTimeDeliveryPercentage
FROM Supplier sup
JOIN PurchaseOrder po
    ON sup.SupplierID = po.SupplierID
WHERE po.ActualDeliveryDate IS NOT NULL
GROUP BY
    sup.SupplierID,
    sup.SupplierName
ORDER BY OnTimeDeliveryPercentage DESC;


/* ---------------------------------------------------------------------
   Q20. Which suppliers may be contributing to inventory problems?

   Connect suppliers to ordered variants and identify variants
   whose available stock is at or below reorder level.

   This identifies an association, not proof that a supplier caused
   the inventory shortage.
   --------------------------------------------------------------------- */

SELECT
    sup.SupplierID,
    sup.SupplierName,
    COUNT(DISTINCT pv.VariantID) AS AffectedVariants,
    SUM(
        CASE
            WHEN i.QuantityAvailable = 0 THEN 1
            ELSE 0
        END
    ) AS OutOfStockRecords,
    SUM(
        CASE
            WHEN i.QuantityAvailable < i.ReorderLevel
                THEN i.ReorderLevel - i.QuantityAvailable
            ELSE 0
        END
    ) AS TotalStockGap
FROM Supplier sup
JOIN PurchaseOrder po
    ON sup.SupplierID = po.SupplierID
JOIN PurchaseOrderItem poi
    ON po.PurchaseOrderID = poi.PurchaseOrderID
JOIN ProductVariant pv
    ON poi.VariantID = pv.VariantID
JOIN Inventory i
    ON pv.VariantID = i.VariantID
WHERE i.QuantityAvailable <= i.ReorderLevel
GROUP BY
    sup.SupplierID,
    sup.SupplierName
ORDER BY
    TotalStockGap DESC;