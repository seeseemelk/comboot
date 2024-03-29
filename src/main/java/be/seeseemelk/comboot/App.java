/*
 * This Java source file was generated by the Gradle 'init' task.
 */
package be.seeseemelk.comboot;

import be.seeseemelk.comboot.connectors.TCPConnector;
import be.seeseemelk.comboot.gui.ComBootGui;

import java.io.IOException;

public class App
{
    public static void main(String[] args) throws Exception
    {
        ComBootGui gui = new ComBootGui();

        /*ComBootGui gui = null;
        try (
            TCPConnector connector = connect();
            ComBootServer server = new ComBootServer(connector);
        )
        {
            if (args.length >= 1)
            {
                String arg = args[0];
                if (arg.equals("--console"))
                {
                    server.openFile(Disks.FLOPPY_A, "disk1.img");
                    //server.openFile(Disks.FLOPPY_A, "bin/asm/test.img");
                    server.setAutoBoot(true);
                    server.run();
                    return;
                }
            }
            gui = new ComBootGui(server);
            gui.run();
        }
        finally
        {
            if (gui != null)
                gui.close();
        }*/
    };

    private static TCPConnector connect() throws IOException
    {
        try
        {
            for (;;)
            {
                try
                {
                    return new TCPConnector("localhost", 4444);
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                    Thread.sleep(500L);
                }
            }
        }
        catch (InterruptedException e)
        {
            throw new IOException(e);
        }
    }
}
// 14 15
