/*
******************************************************************************
**  CarMaker - Version 9.0.2
**  Vehicle Dynamics Simulation Toolkit
**
**  Copyright (C)   IPG Automotive GmbH
**                  Bannwaldallee 60             Phone  +49.721.98520.0
**                  76185 Karlsruhe              Fax    +49.721.98520.99
**                  Germany                      WWW    www.ipg-automotive.com
******************************************************************************
*/

#ifndef _SENSOR_LIDARRSI_H__
#define _SENSOR_LIDARRSI_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef struct tScanPoint {
    int		BeamID;		// Beam ID
    int		EchoID;		// Echo ID (per Beam)
    double	TimeOF;		// Time of flight in nanoseconds
    double	LengthOF;	// Path length in m
    double	Origin[3];	// Ray origin (x,y,z) in FrSensor in rad
    double	Intensity;	// Intensity of reflected light in nano Watt
    double	PulseWidth;	// Echoe Pulse Width in nanoseconds
    int		nRefl;		// Number of reflections
} tScanPoint;

typedef struct tLidarRSI {
    //Output
    int         ScanNumber;     // Number of current raytracing job
    double      ScanTime;       // Time stamp of current raytracing job
    int         nScanPoints;    // Number of scan points
    tScanPoint  *ScanPoint;     // Scan points

    // Input
    double	t_ext[3];	// additional travel of sensor in mount frame [m]
    double	rot_zyx_ext[3];	// additional rotation of sensor [rad]
} tLidarRSI;

extern tLidarRSI *  LidarRSI;
extern int	    LidarRSICount;

int   LidarRSI_Init	(void);
int   LidarRSI_New	(void);
int   LidarRSI_Calc	(double dt);
int   LidarRSI_Cleanup	(void);

int   LidarRSI_FindIndexForName(const char *Name);
// recommended to call in non RT function User_TestRun_Start_atEnd ()
// returns -1 if no sensor found

tLidarRSI *LidarRSI_GetByIndex (int index);

#ifdef __cplusplus
}
#endif

#endif	// #ifndef _SENSOR_LIDARRSI_H__

