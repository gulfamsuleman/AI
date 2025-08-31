using System;
using System.Data;

/// <summary>
/// Summary description for RideTheLightning
/// </summary>
public static class RideTheLightning
{
	public static object GetValue(this DataRow row, string column)
	{
		return row.Table.Columns.Contains(column) ? row[column] : null;
	}

	public static T? GetConvertedNullableValue<T>(this DataRow row, string column, Func<object, T> converter) where T : struct
	{
		if (row.IsNull(column))
			return null;
		else
			return converter(row[column]);
	}

	public static string GetConvertedStringValue(this DataRow row, string column)
	{
		if (row.IsNull(column))
			return null;
		else
			return Convert.ToString(row[column]);
	}

	public static object GetNullableValue(this DataRow row, string column)
	{
		return !DBNull.Value.Equals(row[column]) ? row[column] : null;
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

