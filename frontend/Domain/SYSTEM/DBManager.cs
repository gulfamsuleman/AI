using System;
using System.Data;
using QProcess.Configuration;
using System.Collections.Generic;

namespace DataAccessLayer
{
    public sealed class DBManager: IDBManager, IDisposable
    {
        #region Local Variables

        private IDbConnection idbConnection;
        private IDataReader idataReader;
        private IDbCommand idbCommand;
        private DataProvider providerType;
        private IDbTransaction idbTransaction = null;
        private List<IDbDataParameter> idbParameters = new List<IDbDataParameter>();
        private string strConnection;
        private bool _Disposed; // implementing IDisposable

        // for batch transaction only
        private bool enableBatchTransaction = false;
        private List<Exception> batchException = new List<Exception>();

        #endregion

        #region Constructors and Destructor

        public DBManager() {
            this.providerType = DataProvider.SqlServer;
            this.strConnection = AppSettings.Get("database").ToString();
        }

        public DBManager(DataProvider providerType)
        {
          this.providerType = providerType;
          this.strConnection = AppSettings.Get("database").ToString();
        }
 
        public DBManager(DataProvider providerType, string connectionString)
        {
          this.providerType = providerType;

          if (connectionString != null && connectionString.Trim() != "")
              this.strConnection = connectionString;
          else
              this.strConnection = AppSettings.Get("database").ToString();
        }

        ~DBManager()
	    {
		    Dispose (false);
	    }

    #endregion

        #region Properties

        public bool EnableBatchTransaction
        {
            get { return enableBatchTransaction; }
            set { enableBatchTransaction = value; }
        }

        public IDbConnection Connection
        {
            get { return idbConnection; }
        }
 
        public IDataReader DataReader
        {
            get { return idataReader; }
            set { idataReader = value; }
        }
 
        public DataProvider ProviderType
        {
            get { return providerType; }
            set { providerType = value; }
        }
 
        public string ConnectionString
        {
            get { return strConnection; }
            set { strConnection = value; }
        }
 
        public IDbCommand Command
        {
            get { return idbCommand; }
        }
 
        public IDbTransaction Transaction
        {
            get { return idbTransaction; }
        }
 
        public List<IDbDataParameter> Parameters
        {
            get { return idbParameters; }
        }

        public List<Exception> BatchException
        {
            get { return batchException; }
        }

        #endregion

        #region Implement IDisposable

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (_Disposed)
            {
                return;
            }

            if (disposing)
            {
                this.Close();
                this.idbCommand = null;
                this.idbTransaction = null;
                this.idbConnection = null;
            }

            _Disposed = true;
        }

        #endregion

        #region Private Methods
 
        private void AttachParameters(IDbCommand command, List<IDbDataParameter> commandParameters)
        {
            foreach (IDbDataParameter idbParameter in commandParameters)
            {
                if ((idbParameter.Direction == ParameterDirection.InputOutput || idbParameter.Direction == ParameterDirection.Output) && (idbParameter.Value == null))
                {
                    idbParameter.Value = DBNull.Value;
                    // when output parameter is a varchar then set size to max(8000) to avoid exception in ADO.NET
                    if (idbParameter.Direction == ParameterDirection.Output && idbParameter.Size == 0
                        && idbParameter.DbType == DbType.String)
                    {
                        idbParameter.Size = 8000;
                    }
                }

                // convert CTS null to DBNull.Value
                if (idbParameter.Value == null) idbParameter.Value = DBNull.Value;

                command.Parameters.Add(idbParameter);
          }
        }
 
        private void PrepareCommand(IDbCommand command, IDbConnection connection,
          IDbTransaction transaction, CommandType commandType, string commandText, 
          List<IDbDataParameter> commandParameters)
        {
            command.Connection = connection;
            command.CommandText = commandText;
            command.CommandType = commandType;
 
            if (transaction != null)
            {
                command.Transaction = transaction;
            }
            
            if (commandParameters != null && commandParameters.Count > 0)
            {
                AttachParameters(command, commandParameters);
            }
        }

        #endregion

        #region Public Methods

        public void Open()
        {
            idbConnection = DBManagerFactory.GetConnection(this.providerType);
            idbConnection.ConnectionString = this.ConnectionString;
            if (idbConnection.State != ConnectionState.Open)
                idbConnection.Open();
            this.idbCommand = DBManagerFactory.GetCommand(this.ProviderType);
            this.idbCommand.CommandTimeout = 120;
        }
 
        public void Close()
        {
            if (idbConnection.State != ConnectionState.Closed)
                idbConnection.Close();
        }

        // TODO: Need to test to make sure dynamic value is allowed at runtime and is correct
        public object GetOutputParameterValue(string paramName)
        {
            object param = null;

            if (idbCommand != null)
            {
                dynamic result = idbCommand.Parameters[paramName];
                param = result.Value;
            }

            // convert DBNull.Value to CTS null
            if (param == DBNull.Value) param = null;

            return param;
        }

        public DbType GetOutputParameterType(string paramName)
        {
            DbType type = DbType.Object;

            if (idbCommand != null)
            {
                dynamic result = idbCommand.Parameters[paramName];
                type = result.DbType;
            }

            return type;
        }
 
        public void ClearParameters()
        {
            idbParameters.Clear();
        }

        public IDbDataParameter Parameter(string paramName)
        {
            for (int i = 0; i < idbParameters.Count; i++)
            {
                if (idbParameters[i].ParameterName.ToLower().Trim() == paramName.ToLower().Trim())
                    return idbParameters[i];
            }

            return null;
        }

        public void AddParameters(string paramName, ParameterDirection direction, DbType type, object objValue = null)
        {
            IDbDataParameter param = DBManagerFactory.GetParameter(this.providerType);
            param.ParameterName = paramName;
            param.Value = objValue;
            param.Direction = direction;
            param.DbType = type;

            idbParameters.Add(param);
        }

        public void AddParameters(string paramName, object objValue)
        {
            IDbDataParameter param = DBManagerFactory.GetParameter(this.providerType);
            param.ParameterName = paramName;
            param.Value = objValue;
            param.Direction = ParameterDirection.Input;

            idbParameters.Add(param);
        }
 
        public void BeginTransaction()
        {
            if (this.idbTransaction == null)
                idbTransaction = DBManagerFactory.GetTransaction(this.ProviderType, idbConnection);

            this.idbCommand.Transaction = idbTransaction;
        }
 
        public void CommitTransaction()
        {
            if (this.idbTransaction != null)
                this.idbTransaction.Commit();

            idbTransaction = null;
        }

        public void RollBackTransaction()
        {
            if (this.idbTransaction != null)
                this.idbTransaction.Rollback();

            idbTransaction = null;
        }
 
        public int ExecuteNonQuery(CommandType commandType, string commandText)
        {
            if (this.Connection == null) Open();

            this.idbCommand =DBManagerFactory.GetCommand(this.ProviderType);
            PrepareCommand(idbCommand,this.Connection, this.Transaction, commandType, commandText, this.Parameters);
            int returnValue = idbCommand.ExecuteNonQuery();
            // TODO: only clear out parameters if none of the parameters are of type output
            // idbCommand.Parameters.Clear();
            return returnValue;
        }
 
        public object ExecuteScalar(CommandType commandType, string commandText)
        {
            if (this.Connection == null) Open();

            this.idbCommand =DBManagerFactory.GetCommand(this.ProviderType);
            PrepareCommand(idbCommand,this.Connection, this.Transaction, commandType, commandText, this.Parameters);
            object returnValue = idbCommand.ExecuteScalar();
            // TODO: only clear out parameters if none of the parameters are of type output
            // idbCommand.Parameters.Clear();
            return returnValue;
        }
 
        public DataSet ExecuteDataSet(CommandType commandType, string commandText)
        {
            if (this.Connection == null) Open();
            this.idbCommand =DBManagerFactory.GetCommand(this.ProviderType);
            this.idbCommand.CommandTimeout = 0;
            PrepareCommand(idbCommand,this.Connection, this.Transaction, commandType, commandText, this.Parameters);
            IDbDataAdapter dataAdapter =DBManagerFactory.GetDataAdapter(this.ProviderType);
            dataAdapter.SelectCommand = idbCommand;
            DataSet dataSet = new DataSet();
            dataAdapter.Fill(dataSet);
            // TODO: only clear out parameters if none of the parameters are of type output
            // idbCommand.Parameters.Clear();
            return dataSet;
        }
 
        public IDataReader ExecuteReader(CommandType commandType, string commandText)
        {
            if (this.Connection == null) Open();

            this.idbCommand = DBManagerFactory.GetCommand(this.ProviderType);
            idbCommand.Connection = this.Connection;
            PrepareCommand(idbCommand,this.Connection, this.Transaction, commandType, commandText, this.Parameters);
            this.DataReader =idbCommand.ExecuteReader();
            // TODO: only clear out parameters if none of the parameters are of type output
            //idbCommand.Parameters.Clear();
            return this.DataReader;
        }
 
        public void CloseReader()
        {
            if (this.DataReader != null)
                this.DataReader.Close();
        }

        public int BatchExecute(params DBCommand[] dbCommands)
        {
            batchException.Clear();
            int processsed = 0;

            this.providerType = dbCommands[0].ProviderType;
            if (dbCommands[0].connectionString.Trim() != "") this.strConnection = dbCommands[0].connectionString;

            Open(); // start DB connection

            if (enableBatchTransaction) BeginTransaction();

            for (int i = 0; i < dbCommands.Length; i++)
            {
                ClearParameters();

                try
                {
                    DBCommand d = dbCommands[i];
                    // first get all the independent parameters
                    foreach (IDbDataParameter p in d.IDBParameters)
                    {
                        AddParameters(p.ParameterName, p.Direction, p.DbType, p.Value);
                    }

                    // now get all the dependent parameters
                    if (i > 0)
                    {
                        foreach (ParameterExtendedData p in d.ExtendedData)
                        {
                            AddParameters(p.destinationParameterName, p.direction, GetOutputParameterType(p.objectParameterName), GetOutputParameterValue(p.objectParameterName));
                        }
                    }

                    ExecuteNonQuery(d.commandType, d.commandText);

                    processsed += 1;
                }
                catch (Exception ex)
                {
                    batchException.Add(ex);
                    if (enableBatchTransaction)
                    {
                        RollBackTransaction();
                        Close();

                        return processsed;
                    }
                }
            }

            if (enableBatchTransaction) CommitTransaction();

            Close();    // close DB connection

            return processsed;
        }

        #endregion
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

