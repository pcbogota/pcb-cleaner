using System;
using System.Drawing;
using System.Windows.Forms;

class PrintExpertApp
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        Form frm = new Form
        {
            Text = "PrintExpert",
            Size = new Size(400, 250),
            BackColor = Color.Navy,
            ForeColor = Color.White,
            FormBorderStyle = FormBorderStyle.FixedDialog,
            MaximizeBox = false,
            MinimizeBox = false,
            StartPosition = FormStartPosition.CenterScreen
        };

        // Icono hecho en código (cuadro azul oscuro + P blanca)
        frm.Icon = CreateIcon(Color.Navy, "P");

        Label lbl = new Label
        {
            Text = "Soy PrintExpert",
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
                "PrintExpert",
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
        Icon icon = Icon.FromHandle(hIcon);
        // No hacemos Dispose del bmp aquí porque el icono necesita el handle
        return icon;
    }
}
