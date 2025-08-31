using System;
using System.Data;
using System.Collections.Generic;

namespace DataAccessLayer
{
    public class DBCommand : IDisposable
    {
        #region Local Variables

        private List<IDbDataParameter> idbParameters = new List<IDbDataParameter>();
        private string sqlCommand = "";
        private string sqlConnection = "";
        private CommandType cmdType = CommandType.StoredProcedure;
        private bool _Disposed; // implementing IDisposable
        private Guid id = new Guid();
        private DataProvider providerType = DataProvider.SqlServer;
        private List<ParameterExtendedData> extendedData = new List<ParameterExtendedData>();

        #endregion

        #region Properties

        public Guid ID
        {
            get { return id; }
        }

        public CommandType commandType
        {
            get { return cmdType; }
            set { cmdType = value; }
        }

        public DataProvider ProviderType
        {
            get { return providerType; }
            set { providerType = value; }
        }

        public List<IDbDataParameter> IDBParameters
        {
            get { return idbParameters; }
        }

        public List<ParameterExtendedData> ExtendedData
        {
            get { return extendedData; }
        }

        public string commandText
        {
            get { return sqlCommand; }
        }

        public string connectionString
        {
            get { return sqlConnection; }
        }

        #endregion

        #region Constructor and Destructor

        public DBCommand(string spName)
	    {
            this.sqlCommand = spName;
	    }

        public DBCommand(string sqlText, CommandType commandType)
        {
            this.sqlCommand = sqlText;
            this.cmdType = commandType;
        }

        public DBCommand(string sqlText, string connectionString, DataProvider provider = DataProvider.SqlServer, CommandType commandType = CommandType.StoredProcedure)
        {
            this.sqlCommand = sqlText;
            this.sqlConnection = connectionString;
            this.providerType = provider;
            this.cmdType = commandType;
        }

        ~DBCommand()
	    {
		    Dispose (false);
	    }

        #endregion

        #region Public Methods

        public void ClearParamenters()
        {
            idbParameters.Clear();
            extendedData.Clear();
        }

        public object GetOutputParameter(string paramName)
        {
            for (int i = 0; i < idbParameters.Count; i++)
            {
                if (idbParameters[i].ParameterName.ToLower() == paramName.ToLower())
                {
                    if (idbParameters[i].Value == DBNull.Value)
                        return null;
                    else
                        return idbParameters[i].Value;
                }
            }

            return null;
        }

        public void AddParameter(string paramName, object objValue)
        {
            IDbDataParameter param = DBManagerFactory.GetParameter(this.providerType);
            param.ParameterName = paramName;
            param.Value = objValue;
            param.Direction = ParameterDirection.Input;

            idbParameters.Add(param);
        }

        public void UpdateParameter(string paramName, object objValue)
        {
            for (int i = 0; i < idbParameters.Count; i++)
            {
                if (idbParameters[i].ParameterName == paramName)
                {
                    idbParameters[i].Value = objValue;
                    break;
                }
            }
        }

        public void AddParameter(string paramName, ParameterDirection direction, DbType type, object objValue = null)
        {
            IDbDataParameter param = DBManagerFactory.GetParameter(this.providerType);
            param.ParameterName = paramName;
            param.Value = objValue;
            param.Direction = direction;
            param.DbType = type;

            idbParameters.Add(param);
        }

        /// <summary>
        /// use this method to use the output of another DBCommand for the input of the current DBCommand parameter
        /// </summary>
        /// <param name="dbCommand">DBCommand instance that you will get the output value from</param>
        /// <param name="paramName">name of the input parameter for the current DBCommand instance</param>
        /// <param name="outputParamName">name of the output parameter of another DBCommand instance you want to use as your input value</param>
        /// <param name="direction">direction of your input parameter for the current DBCommand instance</param>
        public void AddParameter(DBCommand dbCommand, string paramName, string outputParamName, ParameterDirection direction = ParameterDirection.Input, DbType type = DbType.Object)
        {
            ParameterExtendedData param = new ParameterExtendedData();
            param.objectID = dbCommand.id;
            param.objectParameterName = outputParamName;
            param.destinationParameterName = paramName;
            param.direction = direction;
            param.type = type;

            extendedData.Add(param);
        }

        public int ExecuteNonQuery()
        {
            using (DBManager db = new DBManager(this.providerType, sqlConnection))
            {
                db.Open();

                if (idbParameters.Count > 0)
                {
                    for (int i = 0; i < idbParameters.Count; i++)
                    {
                        
                        if (idbParameters[i].DbType == DbType.Object)
                        {
                            db.AddParameters(idbParameters[i].ParameterName, idbParameters[i].Value);
                        }
                        else
                        {
                            db.AddParameters(idbParameters[i].ParameterName, idbParameters[i].Direction, idbParameters[i].DbType, idbParameters[i].Value);
                        }
                    }
                }

                int result = db.ExecuteNonQuery(cmdType, sqlCommand);

                // retrieve any output value for user to retrieve
                for (int i = 0; i < idbParameters.Count; i++)
                {
                    if (idbParameters[i].Direction == ParameterDirection.Output)
                    {
                        idbParameters[i].Value = db.GetOutputParameterValue(idbParameters[i].ParameterName);
                    }
                }

                return result;
            }
        }

        public object ExecuteScalar()
        {
            using (DBManager db = new DBManager(this.providerType, sqlConnection))
            {
                db.Open();

                if (idbParameters.Count > 0)
                {
                    for (int i = 0; i < idbParameters.Count; i++)
                    {
                        if (idbParameters[i].DbType == DbType.Object)
                        {
                            db.AddParameters(idbParameters[i].ParameterName, idbParameters[i].Value);
                        }
                        else
                        {
                            db.AddParameters(idbParameters[i].ParameterName, idbParameters[i].Direction, idbParameters[i].DbType, idbParameters[i].Value);
                        }
                    }
                }

                object result = db.ExecuteScalar(cmdType, sqlCommand);

                // retrieve any output value for user to retrieve
                for (int i = 0; i < idbParameters.Count; i++)
                {
                    if (idbParameters[i].Direction == ParameterDirection.Output)
                    {
                        idbParameters[i].Value = db.GetOutputParameterValue(idbParameters[i].ParameterName);
                    }
                }

                return result;
            }
        }

        public DataSet ExecuteDataSet()
        {
            using (DBManager db = new DBManager(this.providerType, sqlConnection))
            {
                db.Open();

                if (idbParameters.Count > 0)
                {
                    for (int i = 0; i < idbParameters.Count; i++)
                    {
                        if (idbParameters[i].DbType == DbType.Object)
                        {
                            db.AddParameters(idbParameters[i].ParameterName, idbParameters[i].Value);
                        }
                        else
                        {
                            db.AddParameters(idbParameters[i].ParameterName, idbParameters[i].Direction, idbParameters[i].DbType, idbParameters[i].Value);
                        }
                    }
                }

                DataSet result = db.ExecuteDataSet(cmdType, sqlCommand);

                // retrieve any output value for user to retrieve
                for (int i = 0; i < idbParameters.Count; i++)
                {
                    if (idbParameters[i].Direction == ParameterDirection.Output)
                    {
                        idbParameters[i].Value = db.GetOutputParameterValue(idbParameters[i].ParameterName);
                    }
                }

                return result;
            }
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
                idbParameters = null;
            }

            _Disposed = true;
        }

        #endregion
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

