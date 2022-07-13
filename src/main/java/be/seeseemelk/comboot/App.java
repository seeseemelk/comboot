/*
 * This Java source file was generated by the Gradle 'init' task.
 */
package be.seeseemelk.comboot;

import be.seeseemelk.comboot.connectors.Connector;
import be.seeseemelk.comboot.connectors.TCPConnector;
import be.seeseemelk.comboot.packets.ComHello;
import be.seeseemelk.comboot.packets.ComPacket;
import be.seeseemelk.comboot.packets.ComRead;
import lombok.AllArgsConstructor;

import java.io.IOException;

@AllArgsConstructor
public class App
{
    private final Connector connector;

    private void run() throws IOException
    {
        for (;;)
        {
            ComPacket packet = connector.read();
            System.out.format("Received packet: %s%n", packet);
            switch (packet.getType())
            {
                case HELLO -> handleHello((ComHello) packet);
                case READ -> handleRead((ComRead) packet);
            }
        }
    }

    private void handleHello(ComHello packet)
    {
        System.out.println("Received hello");
    }

    private void handleRead(ComRead packet)
    {
        System.out.println("Received read");
    }

    public static void main(String[] args) throws IOException
    {
        try (TCPConnector connector = new TCPConnector("localhost", 4444))
        {
            new App(connector).run();
        }
    };
}
