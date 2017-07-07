DROP TABLE [dbo].[PlaceImages]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PlaceImages](
	[ImageID] [int] IDENTITY(1,1) NOT NULL,
	[ImagePath] [nvarchar](250) NOT NULL,
	[ImageRaw] [varbinary](max) NULL,
	[PlaceDetected] [varchar](250) NULL,
	[Probability] [float] NULL
)

GO