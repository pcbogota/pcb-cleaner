using System;
using System.Drawing;
using System.Windows.Forms;

class FlexiSignApp
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        Form frm = new Form
        {
            Text = "FlexiSIGN",
            Size = new Size(400, 250),
            BackColor = Color.FromArgb(0, 51, 0),   // verde muy oscuro
            ForeColor = Color.White,
            FormBorderStyle = FormBorderStyle.FixedDialog,
            MaximizeBox = false,
            MinimizeBox = false,
            StartPosition = FormStartPosition.CenterScreen
        };

        // Icono hecho en código (cuadro verde oscuro + F blanca)
        frm.Icon = CreateIcon(Color.FromArgb(0, 51, 0), "F");

        Label lbl = new Label
        {
            Text = "Soy FlexiSIGN",
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", 16, FontStyle.Bold)
        };
        frm.Controls.Add(lbl);

        frm.FormClosing += (sender, e) =>
        {
            DialogResult res = MessageBox.Show(
                "¿Seguro que deseas cerrar?",
                "FlexiSIGN",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (res == DialogResult.No)
                e.Cancel = true;
        };

        Application.Run(frm);
    }

    static Icon CreateIcon(Color bg, string letter)
    {
        Bitmap bmp = new Bitmap(32, 32);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(bg);
            using (Font f = new Font("Segoe UI", 18, FontStyle.Bold))
            using (Brush brush = new SolidBrush(Color.White))
            {
                g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
                SizeF size = g.MeasureString(letter, f);
                float x = (32 - size.Width) / 2;
                float y = (32 - size.Height) / 2;
                g.DrawString(letter, f, brush, x, y);
            }
        }
        IntPtr hIcon = bmp.GetHicon();
        return Icon.FromHandle(hIcon);
    }
}
