
/****** Object:  Table [dbo].[SqlScriptAudit]    Script Date: 10/1/2024 12:41:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SqlScriptAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FileName] [varchar](255) NOT NULL,
	[DateRun] [datetime] NOT NULL,
	[IsSuccess] [bit] NOT NULL,
	[Error] [varchar](8000) NULL,
 CONSTRAINT [PK_SqlScriptAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SqlScriptAudit] ADD  CONSTRAINT [DF_Table_1_Date]  DEFAULT (getdate()) FOR [DateRun]
GO

ALTER TABLE [dbo].[SqlScriptAudit] ADD  CONSTRAINT [DF_SqlScriptAudit_IsSuccess]  DEFAULT ((0)) FOR [IsSuccess]
GO

/* Stored procedure used to add a row to [SqlScriptAudit] */
CREATE PROCEDURE SqlScriptAudit_Add
    @FileName VARCHAR(255),
    @IsSuccess BIT,
    @Error VARCHAR(8000)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO SqlScriptAudit (FileName, IsSuccess, Error)
    VALUES (@FileName, @IsSuccess, @Error);
END
GO


