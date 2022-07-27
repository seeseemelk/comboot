package be.seeseemelk.comboot.gui;

import javax.swing.*;
import java.awt.*;

public class DriveSelector extends JPanel
{
	private final JLabel title;
	private final JLabel source;
	private final JComboBox<DriveSelectorItem> selector;

	public DriveSelector(String drive)
	{
		setMinimumSize(new Dimension(200, 100));

		SpringLayout layout = new SpringLayout();
		setLayout(layout);

		add(title = new JLabel(drive + ":"));
		add(source = new JLabel("Not present"));
		add(selector = new JComboBox<>());

		selector.addItem(DriveSelectorItem.NOT_PRESENT);
		selector.addItem(DriveSelectorItem.VIRTUAL);

		layout.putConstraint(SpringLayout.SOUTH, title, 0, SpringLayout.VERTICAL_CENTER, this);
		layout.putConstraint(SpringLayout.HORIZONTAL_CENTER, title, 0, SpringLayout.HORIZONTAL_CENTER, this);
		layout.putConstraint(SpringLayout.HORIZONTAL_CENTER, source, 0, SpringLayout.HORIZONTAL_CENTER, this);
		layout.putConstraint(SpringLayout.HORIZONTAL_CENTER, selector, 0, SpringLayout.HORIZONTAL_CENTER, this);

		//layout.putConstraint(SpringLayout.NORTH, source, 5, SpringLayout.VERTICAL_CENTER, title);
		//layout.putConstraint(SpringLayout.NORTH, selector, 5, SpringLayout.SOUTH, source);
		layout.putConstraint(SpringLayout.SOUTH, source, 0, SpringLayout.NORTH, selector);
		layout.putConstraint(SpringLayout.SOUTH, selector, 0, SpringLayout.SOUTH, this);
	}

	public void addDriveSelection(DriveSelectorItem item)
	{
		selector.addItem(item);
	}
}
