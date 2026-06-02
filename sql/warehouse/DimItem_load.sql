-- Load procedure and execution for DimItem


USE RentalDW;
GO

CREATE OR ALTER PROCEDURE MiniProject.LoadDimItem
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO MiniProject.DimItem
    (
        item_key,
        item_id,
        model_id,
        category_id,
        maintenance_id,
        category_name,
        model_brand,
        model_name,
        status,
        serial_number,
        hourly_rate,
        is_usable,
        maintenance_start,
        maintenance_end,
        maintenance_type,
        maintenance_cost
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY item.item_id, mr.maintenance_id) AS item_key,
        item.item_id,
        item.model_id,
        model.category_id,
        mr.maintenance_id,
        eq.name AS category_name,
        model.brand AS model_brand,
        model.name AS model_name,
        item.status,
        item.serial_number,
        model.hourly_rate,
        item.is_usable,
        mr.maintenance_start,
        mr.maintenance_end,
        mr.type AS maintenance_type,
        mr.cost AS maintenance_cost
    FROM RentalOperationsDB.MiniProject.Item AS item
    JOIN RentalOperationsDB.MiniProject.Model AS model
        ON model.model_id = item.model_id
    JOIN RentalOperationsDB.MiniProject.EquipmentCategory AS eq
        ON eq.category_id = model.category_id
    LEFT JOIN RentalOperationsDB.MiniProject.MaintenanceRecord AS mr
        ON item.item_id = mr.item_id;
END;
GO

EXEC RentalDW.MiniProject.LoadDimItem;
GO

/*
SELECT * FROM RentalDW.MiniProject.DimItem;
GO
*/