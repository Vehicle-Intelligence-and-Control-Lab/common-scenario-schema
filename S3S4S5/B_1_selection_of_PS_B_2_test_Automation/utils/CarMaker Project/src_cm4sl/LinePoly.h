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
*/

typedef struct tLPoly tLPoly;

struct tLPoly {
    /*Coordinates of the 4 next points of the nearest line on the right side in global frame (Fr0)*/
    double Lx1;
    double Ly1;
    double Lx2;
    double Ly2;
    double Lx3;
    double Ly3;
	double Lx4;
    double Ly4;
	double Rx1;
    double Ry1;
    double Rx2;
    double Ry2;
    double Rx3;
    double Ry3;
	double Rx4;
    double Ry4;

    /*Coefficient a of polynomial y = a*x^3 + b*x^2 + c*x + d , which was calculated from (x1,y1), (x2,y2), (x3,y3) and (x4,y4)*/
    double aL;	
    double bL;
    double cL;
	double dL;
	double aR;	
    double bR;
    double cR;
	double dR;
	
    char Lvalid, Rvalid; /*Flag: results for coefficients a, b and c are valid (1=yes, 0=no)*/
};

extern tLPoly LPoly;

int	LinePoly_TestRun_Start_atEnd	(void);
void	LinePoly_DeclQuants		(void);
int	LinePoly_Calc			(double dt);