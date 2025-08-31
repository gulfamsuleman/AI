using System;
using System.Data;
using System.Collections.Generic;

namespace DataAccessLayer
{
    public enum DataProvider
    {
      SqlServer,OleDb,Odbc
    }

    public struct ParameterExtendedData
    {
        public Guid objectID;
        public string objectParameterName;
        public string destinationParameterName;
        public ParameterDirection direction;
        public DbType type;
    }

    public interface IDBManager
    {
        DataProvider ProviderType
        {
            get;
            set;
        }
 
        string ConnectionString
        {
            get;
            set;
        }
 
        IDbConnection Connection
        {
            get;
        }

        IDbTransaction Transaction
        {
            get;
        }
 
        IDataReader DataReader
        {
            get;
        }

        IDbCommand Command
        {
            get;
        }
 
        List<IDbDataParameter> Parameters
        {
            get;
        }
 
        void Open();
        void BeginTransaction();
        void RollBackTransaction();
        void CommitTransaction();
        object GetOutputParameterValue(string paraName);
        void ClearParameters();
        void AddParameters(string paramName, ParameterDirection direction, DbType type, object objValue);
        IDataReader ExecuteReader(CommandType commandType, string commandText);
        DataSet ExecuteDataSet(CommandType commandType, string commandText);
        object ExecuteScalar(CommandType commandType, string commandText);
        int ExecuteNonQuery(CommandType commandType,string commandText);
        void CloseReader();
        void Close();
        void Dispose();
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

