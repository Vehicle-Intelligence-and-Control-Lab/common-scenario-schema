/*
******************************************************************************
**  CarMaker - Version 6.0.4
**  Vehicle Dynamics Simulation Toolkit
**
**  Copyright (C)   IPG Automotive GmbH
**                  Bannwaldallee 60             Phone  +49.721.98520.0
**                  76185 Karlsruhe              Fax    +49.721.98520.99
**                  Germany                      WWW    http://www.ipg.de
******************************************************************************
**
** Functions
** ---------
**
** Initialization
**
**	LinePoly_DeclQuants ()
**
**
** Main TestRun Start/End:
**
**	LinePoly_TestRun_Start_atEnd ()
**
**
** Main Cycle:
**
**	LinePoly_Calc ()
**
******************************************************************************
**
** Remark
** ---------
**
** Custom Line Detect C-codes
**
**	If detected line points are ordered in reversly, detected line points are re-ordered from nearest points.
**
******************************************************************************
*/

#include "LinePoly.h"
#include <CarMaker.h>
#include <math.h>
#include "Vehicle/Sensor_Line.h"

// Define LinePoly Structure Variable
tLPoly LPoly;

// Define Detected Line Array
#define MAXPNTNO  100

double LDtctPntL0[MAXPNTNO][3];		// Line Detected Points arrary on Left first line,  [][0] = x, [][1] = y, [][2] = z
double LDtctPntR0[MAXPNTNO][3];		// Line Detected Points arrary on Right first line, [][0] = x, [][1] = y, [][2] = z
int LDtctPntL0_nPnt;				// Number of detected point on Left first line by line sensor until road occlusion
int LDtctPntR0_nPnt;				// Number of detected point on Right first lineby line sensor until road occlusion

/*
** LinePoly_DeclQuants ()
**
** declares User Accessible Quantities (used for visualisation with Matlab script PlotLinePoly.m)
**
** call in User_DeclQuants ()
*/
void
LinePoly_DeclQuants (void)
{
    tDDictEntry	*e;
	int i;
	
	for (i=0; i < MAXPNTNO; i++) {
	char user_sbuf1[32];
	char user_sbuf2[32];
	char user_sbuf3[32];
	char user_sbuf4[32];
	char user_sbuf5[32];
	char user_sbuf6[32];
	sprintf (user_sbuf1, "Sensor.LineDtctPnts.L0.%02d.x", i);
	sprintf (user_sbuf2, "Sensor.LineDtctPnts.L0.%02d.y", i);
	sprintf (user_sbuf3, "Sensor.LineDtctPnts.L0.%02d.z", i);
	sprintf (user_sbuf4, "Sensor.LineDtctPnts.R0.%02d.x", i);
	sprintf (user_sbuf5, "Sensor.LineDtctPnts.R0.%02d.y", i);
	sprintf (user_sbuf6, "Sensor.LineDtctPnts.R0.%02d.z", i);
	DDefDouble (NULL, user_sbuf1, "m", &LDtctPntL0[i][0], DVA_None);
	DDefDouble (NULL, user_sbuf2, "m", &LDtctPntL0[i][1], DVA_None);
	DDefDouble (NULL, user_sbuf3, "m", &LDtctPntL0[i][2], DVA_None);
	DDefDouble (NULL, user_sbuf4, "m", &LDtctPntR0[i][0], DVA_None);
	DDefDouble (NULL, user_sbuf5, "m", &LDtctPntR0[i][1], DVA_None);
	DDefDouble (NULL, user_sbuf6, "m", &LDtctPntR0[i][2], DVA_None);
    }
	DDefInt (NULL, "Sensor.LineDtctPnts.L0.nPnt", "", &LDtctPntL0_nPnt, DVA_None);
	DDefInt (NULL, "Sensor.LineDtctPnts.R0.nPnt", "", &LDtctPntR0_nPnt, DVA_None);
	

    DDefDouble4  (NULL, "LinePoly.a_L",	  "",  &LPoly.aL, DVA_None);
    DDefDouble4  (NULL, "LinePoly.b_L",	  "",  &LPoly.bL, DVA_None);
    DDefDouble4  (NULL, "LinePoly.c_L",	  "",  &LPoly.cL, DVA_None);
	DDefDouble4  (NULL, "LinePoly.d_L",	  "",  &LPoly.dL, DVA_None);
	DDefDouble4  (NULL, "LinePoly.a_R",	  "",  &LPoly.aR, DVA_None);
    DDefDouble4  (NULL, "LinePoly.b_R",	  "",  &LPoly.bR, DVA_None);
    DDefDouble4  (NULL, "LinePoly.c_R",	  "",  &LPoly.cR, DVA_None);
	DDefDouble4  (NULL, "LinePoly.d_R",	  "",  &LPoly.dR, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Lx1",	  "m", &LPoly.Lx1, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ly1",	  "m", &LPoly.Ly1, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Lx2",	  "m", &LPoly.Lx2, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ly2",	  "m", &LPoly.Ly2, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Lx3",	  "m", &LPoly.Lx3, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ly3",	  "m", &LPoly.Ly3, DVA_None);
	DDefDouble4  (NULL, "LinePoly.Lx4",	  "m", &LPoly.Lx4, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ly4",	  "m", &LPoly.Ly4, DVA_None);
	DDefDouble4  (NULL, "LinePoly.Rx1",	  "m", &LPoly.Rx1, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ry1",	  "m", &LPoly.Ry1, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Rx2",	  "m", &LPoly.Rx2, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ry2",	  "m", &LPoly.Ry2, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Rx3",	  "m", &LPoly.Rx3, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ry3",	  "m", &LPoly.Ry3, DVA_None);
	DDefDouble4  (NULL, "LinePoly.Rx4",	  "m", &LPoly.Rx4, DVA_None);
    DDefDouble4  (NULL, "LinePoly.Ry4",	  "m", &LPoly.Ry4, DVA_None);
	DDefChar 	 (NULL, "LinePoly.Lvalid","",  &LPoly.Lvalid, DVA_IO_Out);
	e = DDefChar (NULL, "LinePoly.Rvalid","",  &LPoly.Rvalid, DVA_IO_Out);
    DDefStates(e, 2, 0);
}


/*
** LinePoly_TestRun_Start_atEnd ()
**
** Initialises struct at the start of a new TestRun
**
** call in User_TestRun_Start_atEnd ()
*/
int
LinePoly_TestRun_Start_atEnd (void)
{
    LPoly.aL=0;
    LPoly.bL=0;
    LPoly.cL=0;
	LPoly.dL=0;
	LPoly.aR=0;
    LPoly.bR=0;
    LPoly.cR=0;
	LPoly.dR=0;
    LPoly.Lx1=0;
    LPoly.Ly1=0;
    LPoly.Lx2=0;
    LPoly.Ly2=0;
    LPoly.Lx3=0;
    LPoly.Ly3=0;
	LPoly.Lx4=0;
    LPoly.Ly4=0;
	LPoly.Rx1=0;
    LPoly.Ry1=0;
    LPoly.Rx2=0;
    LPoly.Ry2=0;
    LPoly.Rx3=0;
    LPoly.Ry3=0;
	LPoly.Rx4=0;
    LPoly.Ry4=0;
    LPoly.Lvalid=0;
	LPoly.Rvalid=0;

    return 0;
}


/*
** LinePoly_Calc ()
**
** determines coefficients for polynomial y = a*x^2 + b*x + c
** that fits the 3 next points (x1,y1), (x2,y2) and (x3,y3)
** of the nearest line on the right side in global frame (Fr0)
**
** call in User_Calc ()
*/

int
LinePoly_Calc (double dt)
{
    double x1, x2, x3, x4, y1, y2, y3, y4;
    double h1;
	int i, j;
	
    /*Execute only during simulation*/
    if (SimCore.State != SCState_Simulate) return 0;

    /*Execute only if at least 1 line is detected at the left side*/
    if (LineSensor[0].LLines.nLine == 0) {
        LPoly.aL=0;
        LPoly.bL=0;
        LPoly.cL=0;
		LPoly.dL=0;
        LPoly.Lx1=0;
        LPoly.Ly1=0;
        LPoly.Lx2=0;
        LPoly.Ly2=0;
        LPoly.Lx3=0;
        LPoly.Ly3=0;
		LPoly.Lx4=0;
        LPoly.Ly4=0;
		LPoly.Lvalid=0;
		for (i=0; i < MAXPNTNO; i++) {
			LDtctPntL0[i][0] = 0;
			LDtctPntL0[i][1] = 0;
			LDtctPntL0[i][2] = 0;
			LDtctPntL0_nPnt = 0;
		}
        return 0;
    };
	
	/*Execute only if at least 1 line is detected at the right side*/
    if (LineSensor[0].RLines.nLine == 0) {
        LPoly.aR=0;
        LPoly.bR=0;
        LPoly.cR=0;
		LPoly.dR=0;
        LPoly.Rx1=0;
        LPoly.Ry1=0;
        LPoly.Rx2=0;
        LPoly.Ry2=0;
        LPoly.Rx3=0;
        LPoly.Ry3=0;
		LPoly.Rx4=0;
        LPoly.Ry4=0;
		LPoly.Rvalid=0;
		for (i=0; i < MAXPNTNO; i++) {
			LDtctPntR0[i][0] = 0;
			LDtctPntR0[i][1] = 0;
			LDtctPntR0[i][2] = 0;
			LDtctPntR0_nPnt = 0;
		}
        return 0;
    };
	
	
	// For Left First Line,	
	if(LineSensor[0].LLines.L[0].nP == 0) {
		for (i=0; i < MAXPNTNO; i++) {
			LDtctPntL0[i][0] = 0;
			LDtctPntL0[i][1] = 0;
			LDtctPntL0[i][2] = 0;
			LDtctPntL0_nPnt = 0;
		}
	}	
	else {
		
		LDtctPntL0_nPnt = LineSensor[0].LLines.L[0].nP;
		//if vehicle drives to link direction
		if(LineSensor[0].LLines.L[0].ds[0][0] < LineSensor[0].LLines.L[0].ds[1][0]) {
			for (i=0; i < MAXPNTNO; i++) {
				// Store Detected Points
				LDtctPntL0[i][0] = LineSensor[0].LLines.L[0].ds[i][0];
				LDtctPntL0[i][1] = LineSensor[0].LLines.L[0].ds[i][1];
				LDtctPntL0[i][2] = LineSensor[0].LLines.L[0].ds[i][2];				
			}
		}
		else {
			for (i=0; i < LineSensor[0].LLines.L[0].nP; i++) {
				// ReSorting Detected Points				
				j = (LineSensor[0].LLines.L[0].nP - 1) - i;
				
				LDtctPntL0[j][0] = LineSensor[0].LLines.L[0].ds[i][0];
				LDtctPntL0[j][1] = LineSensor[0].LLines.L[0].ds[i][1];
				LDtctPntL0[j][2] = LineSensor[0].LLines.L[0].ds[i][2];				
			}
			for (i=LineSensor[0].LLines.L[0].nP; i < MAXPNTNO; i++) {
				// Set 0 for undetected points
				LDtctPntL0[i][0] = 0;
				LDtctPntL0[i][1] = 0;
				LDtctPntL0[i][2] = 0;				
			}			
		}			
	}
	

	// For Right First Line,	
	if(LineSensor[0].RLines.L[0].nP == 0) {
		for (i=0; i < MAXPNTNO; i++) {
			LDtctPntR0[i][0] = 0;
			LDtctPntR0[i][1] = 0;
			LDtctPntR0[i][2] = 0;
			LDtctPntR0_nPnt = 0;
		}
	}
	else {
		
		LDtctPntR0_nPnt = LineSensor[0].RLines.L[0].nP;
		
		//if vehicle drives to link direction
		if(LineSensor[0].RLines.L[0].ds[0][0] < LineSensor[0].RLines.L[0].ds[1][0]) {
			for (i=0; i < MAXPNTNO; i++) {
				// Store Detected Points
				LDtctPntR0[i][0] = LineSensor[0].RLines.L[0].ds[i][0];
				LDtctPntR0[i][1] = LineSensor[0].RLines.L[0].ds[i][1];
				LDtctPntR0[i][2] = LineSensor[0].RLines.L[0].ds[i][2];				
			}
		}
		else {
			for (i=0; i < LineSensor[0].RLines.L[0].nP; i++) {
				// ReSorting Detected Points				
				j = (LineSensor[0].RLines.L[0].nP - 1) - i;
				
				LDtctPntR0[j][0] = LineSensor[0].RLines.L[0].ds[i][0];
				LDtctPntR0[j][1] = LineSensor[0].RLines.L[0].ds[i][1];
				LDtctPntR0[j][2] = LineSensor[0].RLines.L[0].ds[i][2];				
			}
			for (i=LineSensor[0].RLines.L[0].nP; i < MAXPNTNO; i++) {
				// Set 0 for undetected points
				LDtctPntR0[i][0] = 0;
				LDtctPntR0[i][1] = 0;
				LDtctPntR0[i][2] = 0;				
			}			
		}			
	}	
	/* End of Checking link direction and detected line point sorting */

	
	/* Polynomial coefficients for Left Line */
    /* Calculation of coefficients only once for each set of 4 points*/
    if ((LDtctPntL0[1][0]!= LPoly.Lx1)|(LDtctPntL0[1][1] != LPoly.Ly1)) {

        x1 = LDtctPntL0[1][0];
        y1 = LDtctPntL0[1][1];
        x2 = LDtctPntL0[2][0];
        y2 = LDtctPntL0[2][1];
        x3 = LDtctPntL0[3][0];
        y3 = LDtctPntL0[3][1];
		x4 = LDtctPntL0[4][0];
        y4 = LDtctPntL0[4][1];

        if (!((x4==0)&(y4==0))) {
            /*Coefficients can only be determined, if 4 points are available ((x4,y4) valid)*/
            LPoly.Lvalid = 1;
            h1 = (x1-x2)*(x1-x3)*(x1-x4)*(x2-x3)*(x2-x4)*(x3-x4);	/* Calculate denum */
            if (h1==0) {
                /*if a can not be calculated (division by 0),results not valid*/
                LPoly.aL = 0;
                LPoly.Lvalid = 0;
            } else {
                /*Determine coefficient a*/
                LPoly.aL = ((x2-x3)*(x2-x4)*(x3-x4)*y1 - (x1-x3)*(x1-x4)*(x3-x4)*y2 + (x1-x2)*(x1-x4)*(x2-x4)*y3 - (x1-x2)*(x1-x3)*(x2-x3)*y4)/h1;
            };

            if ((x1==x2)&(x1==x3)&(x1==x4)&(x2==x3)&(x2==x4)&(x3==x4)) {
                /*if b, c and d can not be calculated (division by 0),results not valid*/
                LPoly.bL = 0;
                LPoly.cL = 0;
				LPoly.dL = 0;
                LPoly.Lvalid = 0;
            } else {
                /*Determine coefficients b, c and d*/
                LPoly.bL = (-x2-x3-x4)*y1/((x1-x2)*(x1-x3)*(x1-x4)) + (-x1-x3-x4)*y2/((x2-x1)*(x2-x3)*(x2-x4)) + (-x1-x2-x4)*y3/((x3-x1)*(x3-x2)*(x3-x4)) + (-x1-x2-x3)*y4/((x4-x1)*(x4-x2)*(x4-x3));
                LPoly.cL = (x2*x3+x2*x4+x3*x4)*y1/((x1-x2)*(x1-x3)*(x1-x4)) + (x1*x3+x1*x4+x3*x4)*y2/((x2-x1)*(x2-x3)*(x2-x4)) + (x1*x2+x1*x4+x2*x4)*y3/((x3-x1)*(x3-x2)*(x3-x4)) + (x1*x2+x1*x3+x2*x3)*y4/((x4-x1)*(x4-x2)*(x4-x3));
				LPoly.dL = (-x2*x3*x4)*y1/((x1-x2)*(x1-x3)*(x1-x4)) + (-x1*x3*x4)*y2/((x2-x1)*(x2-x3)*(x2-x4)) + (-x1*x2*x4)*y3/((x3-x1)*(x3-x2)*(x3-x4)) + + (-x1*x2*x3)*y4/((x4-x1)*(x4-x2)*(x4-x3));
            };

        } else {
            /*If not enough points to determine coefficients,results not valid*/
            LPoly.Lvalid = 0;
            LPoly.aL = 0;
            LPoly.bL = 0;
            LPoly.cL = 0;
			LPoly.dL = 0;
        };
		
		    /*Remember last points used*/
            LPoly.Lx1=x1;
            LPoly.Ly1=y1;
            LPoly.Lx2=x2;
            LPoly.Ly2=y2;
            LPoly.Lx3=x3;
            LPoly.Ly3=y3;
			LPoly.Lx4=x4;
            LPoly.Ly4=y4;
    };
	
	/* Polynomial coefficients for Right Line */
	/*Calculation of coefficients only once for each set of 4 points*/
    if ((LDtctPntR0[1][0] != LPoly.Rx1)|(LDtctPntR0[1][1] != LPoly.Ry1)) {

        x1 = LDtctPntR0[1][0];
        y1 = LDtctPntR0[1][1];
        x2 = LDtctPntR0[2][0];
        y2 = LDtctPntR0[2][1];
        x3 = LDtctPntR0[3][0];
        y3 = LDtctPntR0[3][1];
		x4 = LDtctPntR0[4][0];
        y4 = LDtctPntR0[4][1];

        if (!((x4==0)&(y4==0))) {
            /*Coefficients can only be determined, if 4 points are available ((x4,y4) valid)*/
            LPoly.Rvalid = 1;
            h1 = (x1-x2)*(x1-x3)*(x1-x4)*(x2-x3)*(x2-x4)*(x3-x4);	/* Calculate denum */
            if (h1==0) {
                /*if a can not be calculated (division by 0),results not valid*/
                LPoly.aR = 0;
                LPoly.Rvalid = 0;
            } else {
                /*Determine coefficient a*/
                LPoly.aR = ((x2-x3)*(x2-x4)*(x3-x4)*y1 - (x1-x3)*(x1-x4)*(x3-x4)*y2 + (x1-x2)*(x1-x4)*(x2-x4)*y3 - (x1-x2)*(x1-x3)*(x2-x3)*y4)/h1;
            };

            if ((x1==x2)&(x1==x3)&(x1==x4)&(x2==x3)&(x2==x4)&(x3==x4)) {
                /*if b, c and d can not be calculated (division by 0),results not valid*/
                LPoly.bR = 0;
                LPoly.cR = 0;
				LPoly.dR = 0;
                LPoly.Rvalid = 0;
            } else {
                /*Determine coefficients b, c and d*/
                LPoly.bR = (-x2-x3-x4)*y1/((x1-x2)*(x1-x3)*(x1-x4)) + (-x1-x3-x4)*y2/((x2-x1)*(x2-x3)*(x2-x4)) + (-x1-x2-x4)*y3/((x3-x1)*(x3-x2)*(x3-x4)) + (-x1-x2-x3)*y4/((x4-x1)*(x4-x2)*(x4-x3));
                LPoly.cR = (x2*x3+x2*x4+x3*x4)*y1/((x1-x2)*(x1-x3)*(x1-x4)) + (x1*x3+x1*x4+x3*x4)*y2/((x2-x1)*(x2-x3)*(x2-x4)) + (x1*x2+x1*x4+x2*x4)*y3/((x3-x1)*(x3-x2)*(x3-x4)) + (x1*x2+x1*x3+x2*x3)*y4/((x4-x1)*(x4-x2)*(x4-x3));
				LPoly.dR = (-x2*x3*x4)*y1/((x1-x2)*(x1-x3)*(x1-x4)) + (-x1*x3*x4)*y2/((x2-x1)*(x2-x3)*(x2-x4)) + (-x1*x2*x4)*y3/((x3-x1)*(x3-x2)*(x3-x4)) + + (-x1*x2*x3)*y4/((x4-x1)*(x4-x2)*(x4-x3));
            };

        } else {
            /*If not enough points to determine coefficients,results not valid*/
            LPoly.Rvalid = 0;
            LPoly.aR = 0;
            LPoly.bR = 0;
            LPoly.cR = 0;
			LPoly.dR = 0;
        };
		
		    /*Remember last points used*/
            LPoly.Rx1=x1;
            LPoly.Ry1=y1;
            LPoly.Rx2=x2;
            LPoly.Ry2=y2;
            LPoly.Rx3=x3;
            LPoly.Ry3=y3;
			LPoly.Rx4=x4;
            LPoly.Ry4=y4;
    };

    return 0;
}
