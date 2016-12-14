unit uFormHanoi;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Viewport3D, FMX.Types3D, System.Math.Vectors,
  FMX.MaterialSources, FMX.Objects3D, FMX.Controls3D;

type
  TFormHanoi = class(TForm)
    ToolBar1: TToolBar;
    btnStart: TButton;
    lbMove: TLabel;
    Viewport3D: TViewport3D;
    LightTopLeft: TLight;
    Dummy: TDummy;
    lmsSaddlebrown: TLightMaterialSource;
    lmsBlue: TLightMaterialSource;
    lmsCrimson: TLightMaterialSource;
    lmsTurquoise: TLightMaterialSource;
    lmsYellow: TLightMaterialSource;
    rcBase: TRoundCube;
    cGauche: TCylinder;
    cMilieu: TCylinder;
    cDroit: TCylinder;
    cPiece1: TCylinder;
    cPiece2: TCylinder;
    cPiece3: TCylinder;
    cPiece4: TCylinder;
    procedure cPiece1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure cPiece1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single; RayPos, RayDir: TVector3D);
    procedure cPiece1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FDefaultPoint : TPoint3D;

    procedure StartGame;
    procedure LockUnlock;
    procedure CheckGameState;
  public
    { Déclarations publiques }
  end;

var
  FormHanoi: TFormHanoi;

implementation

uses
   FMX.Ani, System.Math, System.Generics.Collections;

{$R *.fmx}

procedure TFormHanoi.btnStartClick(Sender: TObject);
begin
   StartGame;
end;

procedure TFormHanoi.cPiece1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
var
   Piece : TCylinder;
begin
   // on utilise le clic gauche de la souris
   if (ssLeft in Shift) then
   begin
      // on cast le sender en TClylinder
      Piece := Sender as TCylinder;

      if not Piece.Locked then
      begin
         // et on "capture" la pièce dans le MouseDown car
         // ensuite on pourra la bouger avec le MouseMove
         // si on enlève cette ligne et qu'on passe au dessus
         // d'un autre cylindre il bougera en fonction de la souris
         // et cela fera n'importe quoi
         Piece.AutoCapture          := True;
         // RayPos et RayDir permette de récupérer la position et la direction
         // du rayon sur lequel nous avons cliqué avec la souris
         // on modifie le point avec un X=1, Y=1 et Z=0 pour gérer la profondeur
         // on soustrait pour avoir la pièce au dessus de la table de jeu
         // et on change la position du point pivot
         Piece.RotationCenter.Point := Piece.Position.Point - (RayPos.Length * TPoint3D(RayDir)) * Point3D(1, 1, 0);
         // on en profite aussi pour sauvegarder le point de départ
         FDefaultPoint              := Piece.Position.Point;
      end
   end;
end;

procedure TFormHanoi.cPiece1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single; RayPos, RayDir: TVector3D);
var
   Piece    : TCylinder;
   Piquet   : TFmxObject;
   Pt3D     : TPoint3D;
   PtPiquet : TPoint3D;
begin
   if (ssLeft in Shift) then
   begin
      Piece := Sender as TCylinder;

      if not Piece.Locked then
      begin
         // récupération d'un nouveau point (3D) en fonction de la souris
         Pt3D := Piece.RotationCenter.Point + (RayPos.Length * TPoint3D(RayDir)) * Point3D(1, 1, 0);

         // la hauteur d'un piquet (3) et de notre pièce (0.5)
         // l'effet ne sera pas fait sur notre pièce
         // est au dessus d'un piquet
         if Pt3D.Y > -3.5 then
         begin
            for Piquet in rcBase.Children do
            begin
               // récupération des piquets
               if Piquet is TCylinder then
               begin
                  PtPiquet := TCylinder(Piquet).Position.Point;

                  // si un piquet se trouve à plus ou moins 0.5
                  // alors on va positionner le disque dessus
                  // pour donner un effet aimenté
                  if ((PtPiquet.X - 1) < Pt3D.X) and ((PtPiquet.X + 1) > Pt3D.X) then
                     Pt3D.X := PtPiquet.X
               end;
            end;
         end;

         Piece.Position.Point := Pt3D;
      end;
   end;
end;

procedure TFormHanoi.cPiece1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
var
   Piece                  : TCylinder;
   iNbAtThisPos           : integer;
   Piquet                 : TFmxObject;
   iPiquet, iPiece        : integer;
   bOnStake               : boolean;
   bSmallerPieceAtThisPos : boolean;
begin
   // quand on lache la pièce
   Piece := Sender as TCylinder;

   if not Piece.Locked then
   begin
      Piece.AutoCapture      := False;
      bSmallerPieceAtThisPos := False;
      bOnStake               := False;
      iNbAtThisPos           := 0;
      iPiquet                := 0;

      // il faut être sur un piquet
      while (iPiquet <= rcBase.Children.Count - 1) and not bOnStake do
      begin
         Piquet := rcBase.Children[iPiquet];

         // récupération des piquets
         if Piquet is TCylinder then
         begin
            // il y a un piquet à cette position
            if TCylinder(Piquet).Position.X = Piece.Position.X then
            begin
               bOnStake              := True;
               iPiece                := 0;

               // on regarde les pièces présentes à cette position
               while (iPiece <= Dummy.Children.Count - 1) and not bSmallerPieceAtThisPos do
               begin
                  if (Dummy.Children[iPiece] <> Piece) and
                     (Dummy.Children[iPiece] is TCylinder) and
                     (TCylinder(Dummy.Children[iPiece]).Position.Point.X = Piece.Position.Point.X) then
                  begin
                     // si il y a une pièce plus petite on va annuler le drag&drop
                     if TCylinder(Dummy.Children[iPiece]).Width < Piece.Width then
                        bSmallerPieceAtThisPos := True
                     else
                        // on incrémente le nombre de pièce plus petite déjà présentes
                        Inc(iNbAtThisPos);
                  end;

                  Inc(iPiece);
               end;
            end;
         end;

         Inc(iPiquet);
      end;

      // si on n'est pas sur un piquet ou qu'il y a déjà
      // une pièce plus petite à cet emplacement
      if not bOnStake or bSmallerPieceAtThisPos then
      begin
         // on la remet au point de départ
         Piece.Position.Point := FDefaultPoint;
         // on donne un effet de clignotement
         TAnimator.AnimateFloat(Piece, 'Opacity', 0);
         TAnimator.AnimateFloat(Piece, 'Opacity', 1);
      end
      else
      begin
         // on fait tomber la pièce sur la base
         // la hauteur est calculée par rapport au nombre de pieces
         // déjà présentes, la taille d'une pièce est de 0.5
         TAnimator.AnimateFloatWait(Piece, 'Position.Y', iNbAtThisPos * -0.5, 0.5, TAnimationType.Out, TInterpolationType.Bounce);

         // on va incrémenter le nombre de mouvement
         // mais uniquement si on change de piquet
         // afin de ne pas faire un +1 si on prend
         // la pièce et qu'on la relache au même endroit
         if FDefaultPoint.X <> Piece.Position.Point.X then
         begin
            // sauvegarde et affichage du nombre de mouvements
            lbMove.Tag  := lbMove.Tag + 1;
            lbMove.Text := 'Mouvements : ' + lbMove.Tag.ToString;
         end;

         // gestion du blocage et déblocage des pièces
         // seule la première peux être bougée
         LockUnlock;

         // on regarde si la partie est gagnée
         CheckGameState;
      end;
   end;
end;

procedure TFormHanoi.FormCreate(Sender: TObject);
var
   FmxObj : TFmxObject;
begin
   // intialisation de la position de départ par
   // rapport à l'emplacement en conception
   for FmxObj in Dummy.Children do
   begin
      if FmxObj is TCylinder then
         TCylinder(FmxObj).Position.DefaultValue := TCylinder(FmxObj).Position.Point;
   end;
end;

procedure TFormHanoi.FormShow(Sender: TObject);
begin
   // lancement d'une partie
   StartGame;
end;

procedure TFormHanoi.LockUnlock;
var
   Piece   : TFmxObject;
   iCompte : integer;
begin
   // permet de bloquer et debloquer les pièces
   for Piece in Dummy.Children do
   begin
      // normalement il y a uniquement des TCylinder sur le Dummy
      // mais on ne sais jamais ...
      if Piece is TCylinder then
      begin
         iCompte                 := 0;
         TCylinder(Piece).Locked := False;

         // si on trouve une pièce plus petite sur le piquet on bloque
         while (iCompte <= Dummy.Children.Count - 1) and not TCylinder(Piece).Locked do
         begin
            TCylinder(Piece).Locked := (TCylinder(Dummy.Children[iCompte]).Position.X = TCylinder(Piece).Position.X) and
                                       (TCylinder(Dummy.Children[iCompte]).Width < TCylinder(Piece).Width);

            Inc(iCompte);
         end;
      end;
   end;
end;

procedure TFormHanoi.CheckGameState;
var
   bWin : boolean;
   i    : integer;
begin
   bWin := True;
   i    := 0;

   // il faut que toutes les pièces soit sur le piquet droit
   while (i <= Dummy.Children.Count - 1) and bWin do
   begin
      bWin := TCylinder(Dummy.Children[i]).Position.X = cDroit.Position.X;
      Inc(i);
   end;

   if bWin then
   begin
      ShowMessage('Gagné !' + #10#13 + lbMove.Tag.ToString + ' mouvements');
      StartGame;
   end;
end;

procedure TFormHanoi.StartGame;
var
   FmxObj : TFmxObject;
   Pt3D   : TPoint3D;
begin
   lbMove.Tag  := 0;
   lbMove.Text := 'Mouvements';

   for FmxObj in Dummy.Children do
   begin
      if FmxObj is TCylinder then
      begin
         // seule la pièce la plus petite est disponible
         // quand on commence une partie
         TCylinder(FmxObj).Locked := FmxObj <> cPiece4;

         // récupération de l'emplacement par défaut
         Pt3D := TCylinder(FmxObj).Position.DefaultValue;

         if Pt3D <> TCylinder(FmxObj).Position.Point then
         begin
            // on fait monter la pièce
            TAnimator.AnimateFloatWait(FmxObj, 'Position.Y', -3.5);
            // on la déplace à sa position X d'origine
            TAnimator.AnimateFloatWait(FmxObj, 'Position.X', Pt3D.X);
            // on la repose à son emplacement initiale
            TAnimator.AnimateFloatWait(FmxObj, 'Position.Y', Pt3D.Y);
         end;
      end;
   end;
end;

end.
